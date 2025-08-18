import os
from typing import List, Optional
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import pandas as pd
import numpy as np
from fastapi import HTTPException
from sqlalchemy import text
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import StandardScaler
from sklearn.metrics.pairwise import cosine_similarity
from scipy.sparse import hstack, csr_matrix
from typing import List

# AI recommendation engine analyzes the genres, descriptions,
# and ratings of books the user has previously borrowed,
# computes their similarity to the available collection,
# and suggests the most relevant matches.

# DB connection 
DB_URL = os.getenv(
    "DB_URL",
    r"mssql+pyodbc://@localhost\SQLEXPRESS/LibraryDb?driver=ODBC+Driver+17+for+SQL+Server&Trusted_Connection=yes&TrustServerCertificate=yes"
)
engine = create_engine(DB_URL, future=True)
SessionLocal = sessionmaker(bind=engine, future=True)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
        
# FastAPI & CORS
app = FastAPI(title="Library AI (simple)")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],      
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MIN_POS = 3

#Take users previous borrowings
def fetch_user_positives_df(db, user_id: int) -> pd.DataFrame:
    rows = db.execute(text("""
        SELECT DISTINCT 
               b.Id         AS id,
               b.Title      AS title,
               b.Author     AS author,
               b.Genre      AS genre,
               b.Description AS description,
               b.PageCount  AS pageCount,
               b.Rating     AS rating
        FROM BorrowRecords r
        JOIN Books b ON b.Id = r.BookId
        WHERE r.UserId = :uid
    """), {"uid": user_id}).mappings().all()
    return pd.DataFrame(rows)

# Fetch available options. The ones that is available and not archived and not borrowed by the user
def _fetch_available_candidates_df(db, user_id: int) -> pd.DataFrame:
    rows = db.execute(text("""
        SELECT 
               b.Id         AS id,
               b.Title      AS title,
               b.Author     AS author,
               b.Genre      AS genre,
               b.Description AS description,
               b.PageCount  AS pageCount,
               b.Rating     AS rating
        FROM Books b
        WHERE (b.IsArchived = 0 OR b.IsArchived IS NULL)
          AND b.IsAvailable = 1
          AND b.Id NOT IN (SELECT BookId FROM BorrowRecords WHERE UserId = :uid)
    """), {"uid": user_id}).mappings().all()
    return pd.DataFrame(rows)


def _build_text(df: pd.DataFrame) -> pd.Series:
    for c in ["title", "genre", "author", "description"]:
        if c not in df.columns:
            df[c] = ""
    return (
        df["title"].fillna("").astype(str) + " [SEP] " +
        df["genre"].fillna("").astype(str) + " [SEP] " +
        df["author"].fillna("").astype(str) + " [SEP] " +
        df["description"].fillna("").astype(str)
    )

@app.get("/recommend_similar", response_model=List[int])
def recommend_similar(user_id: int, top_k: int = 3, db=Depends(get_db)):
    try:
        # 1) positives
        pos = fetch_user_positives_df(db, user_id).reset_index(drop=True)
        if pos.empty or len(pos) < MIN_POS:
            return []

        # 2) candidates
        candidates = _fetch_available_candidates_df(db, user_id).reset_index(drop=True)
        if candidates.empty:
            return []

        n_pos, n_cand = len(pos), len(candidates)

        # 3) TEXT features
        pos_text = _build_text(pos)
        c_text   = _build_text(candidates)

        vec = TfidfVectorizer(max_features=5000, ngram_range=(1, 2))
        X_text = vec.fit_transform(pd.concat([pos_text, c_text], axis=0, ignore_index=True))
        X_pos_text = X_text[:n_pos]
        X_c_text   = X_text[n_pos:]

        # 4) NUMERIC features (rating, pageCount)
        for col in ["rating", "pageCount"]:
            if col not in pos.columns:
                pos[col] = 0
            if col not in candidates.columns:
                candidates[col] = 0

        pos_num = pos[["rating", "pageCount"]].fillna(0).to_numpy(dtype=float)
        c_num   = candidates[["rating", "pageCount"]].fillna(0).to_numpy(dtype=float)

        scaler = StandardScaler()
        scaler.fit(np.vstack([pos_num, c_num]))   # fit on combined
        X_pos_num = scaler.transform(pos_num)
        X_c_num   = scaler.transform(c_num)

        # DEBUG: print shapes just before combining
        print("n_pos", n_pos, "n_cand", n_cand)
        print("X_pos_text", X_pos_text.shape, "X_c_text", X_c_text.shape)
        print("X_pos_num", X_pos_num.shape, "X_c_num", X_c_num.shape)

        # 5) Combine blocks
        USE_NUM = True  # set False to test text-only path quickly
        if USE_NUM:
            alpha_txt, beta_num = 1.0, 1.0
            X_pos = hstack([alpha_txt * X_pos_text, beta_num * csr_matrix(X_pos_num)], format="csr")
            X_c   = hstack([alpha_txt * X_c_text,   beta_num * csr_matrix(X_c_num)],   format="csr")
        else:
            X_pos, X_c = X_pos_text, X_c_text

        # Sanity checks
        assert X_pos.shape[0] == n_pos,        (X_pos.shape, n_pos)
        assert X_c.shape[0]   == n_cand,       (X_c.shape, n_cand)
        assert X_pos.shape[1] == X_c.shape[1], (X_pos.shape, X_c.shape)

        # 6) User profile & similarity

        # mean() on a sparse matrix returns a numpy.matrix; convert to ndarray
        user_vec_mat = X_pos.mean(axis=0)                # 1 x D
        # safe conversion to ndarray with proper shape
        user_vec = np.asarray(user_vec_mat).reshape(1, -1)

        # now compute cosine similarity (X_c can stay sparse)
        sims = cosine_similarity(X_c, user_vec).ravel()

        # 7) Rank & return top ids
        candidates = candidates.copy()
        candidates["sim"] = sims
        candidates = candidates.sort_values("sim", ascending=False)

        top_ids = candidates.head(top_k)["id"].astype(int).tolist()
        return top_ids

    except AssertionError as ae:
        # Helpful error surface during dev
        raise HTTPException(status_code=500, detail=f"Shape assertion failed: {ae}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
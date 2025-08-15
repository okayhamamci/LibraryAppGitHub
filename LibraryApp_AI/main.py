import os
from typing import List, Optional
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import pandas as pd
import numpy as np
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


@app.get("/recommedn_similar", response_model=List[int]) # Returns the list of book IDs
def recommend_similar(user_id: int, top_k: int = 3, db=Depends(get_db)):
    
    possible_options = fetch_user_positives_df(db, user_id)
    
    # User must have at least 3 previous borrowings
    if len(possible_options) < MIN_POS:
        return []
    
    # If there is no possbile candidates return null
    candidates = _fetch_available_candidates_df(db, user_id)
    if candidates.empty:
        return []
    
    vector = TfidfVectorizer(max_features=5000, ngram_range=(1, 2))
    X_text = vector.fit_transform(pd.concat([possible_options, candidates], axis=0))
    
    X_pos_text = X_text[:len(possible_options)]
    X_c_text = X_text[:len(possible_options)]
    
    # Numeric features (fill missing with 0)
    for col in ["rating", "pageCount"]:
        if col not in possible_options.columns:
            possible_options[col] = 0
        if col not in candidates.columns:
            candidates[col] = 0
    pos_num = possible_options[["rating", "pageCount"]].fillna(0).to_numpy(dtype=float)
    c_num   = candidates[["rating", "pageCount"]].fillna(0).to_numpy(dtype=float)
    
    scaler = StandardScaler()
    X_num_all = scaler.fit_transform(np.vstack([pos_num, c_num]))
    X_pos_num = X_num_all[:len(possible_options)]
    X_c_num   = X_num_all[len(possible_options):]
    
    # Combining the text features and numeric features into a single feature matrix
    X_pos = hstack([X_pos_text, csr_matrix(X_pos_num)], format="csr")
    X_c   = hstack([X_c_text, csr_matrix(X_c_num)], format="csr")
    
    # --- User profile vector = mean of positive vectors ---
    user_vec = X_pos.mean(axis=0)
    
    # --- Cosine similarity to candidates ---
    sims = cosine_similarity(X_c, user_vec)[:, 0]
    
    # Rank candidates by similarity
    cands = cands.copy()
    cands["sim"] = sims
    cands = cands.sort_values("sim", ascending=False)

    # Take top 3 and return IDs
    top_ids = cands.head(top_k)["id"].astype(int).tolist()
    return top_ids
    



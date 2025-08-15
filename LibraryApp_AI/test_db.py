import pyodbc
import sqlalchemy as sa


# For now dont use env file.
DB_URL = r"mssql+pyodbc://@localhost\SQLEXPRESS/LibraryDb?driver=ODBC+Driver+17+for+SQL+Server&Trusted_Connection=yes&TrustServerCertificate=yes"


try:
    # Engine oluştur
    engine = sa.create_engine(DB_URL, future=True)
    
    with engine.connect() as conn:
        print("✅ Bağlantı başarılı!")
        server_time = conn.execute(sa.text("SELECT SYSDATETIME()")).scalar_one()
        print("Sunucu zamanı:", server_time)
        
        row = conn.execute(sa.text("SELECT DB_NAME() AS db, SUSER_SNAME() AS login")).mappings().first()
        print(f"Veritabanı: {row['db']} | Kullanıcı: {row['login']}")
except Exception as e:
    print("❌ Bağlantı hatası:", e)
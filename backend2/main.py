# backend2/main.py
from fastapi import FastAPI, Depends, HTTPException, UploadFile, File
from fastapi.staticfiles import StaticFiles
from sqlalchemy import create_engine, Column, Integer, String, Numeric, Boolean, Text, DateTime, ForeignKey
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from sqlalchemy.sql import func
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from fastapi.middleware.cors import CORSMiddleware
import shutil
import os

# -------------------------------------------------------------------
# 1. CONFIGURACIÓN DE LA BASE DE DATOS (POSTGRESQL)
# -------------------------------------------------------------------
# Formato: postgresql://usuario:contraseña@servidor:puerto/nombre_base_datos
SQLALCHEMY_DATABASE_URL = "postgresql://postgres:301125@localhost:5432/inventarioTienda?client_encoding=utf8"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# -------------------------------------------------------------------
# 2. MODELOS RELACIONALES (Mapeo exacto de tu script SQL)
# -------------------------------------------------------------------
class Categoria(Base):
    __tablename__ = "categorias"
    id_categoria = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False, unique=True)

class Producto(Base):
    __tablename__ = "productos"
    id_producto = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(255), nullable=False)
    descripcion = Column(Text, nullable=True)
    precio = Column(Numeric(10, 2), nullable=False)
    stock = Column(Integer, nullable=False)
    url_imagen = Column(String(500), nullable=True)
    # Los timestamps y valores por defecto los maneja la base de datos
    fecha_creacion = Column(DateTime, server_default=func.now(), nullable=False)
    fecha_actualizacion = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)
    activo = Column(Boolean, default=True, nullable=False)
    id_categoria = Column(Integer, ForeignKey("categorias.id_categoria", ondelete="RESTRICT", onupdate="CASCADE"), nullable=False)

# Crear las tablas si no existen
Base.metadata.create_all(bind=engine)

# -------------------------------------------------------------------
# 3. ESQUEMAS PYDANTIC (Validación de datos de entrada/salida)
# -------------------------------------------------------------------
class CategoriaCreate(BaseModel):
    nombre: str

class CategoriaResponse(CategoriaCreate):
    id_categoria: int
    class Config:
        from_attributes = True

class ProductoCreate(BaseModel):
    nombre: str
    descripcion: Optional[str] = None
    precio: float
    stock: int
    url_imagen: Optional[str] = None
    id_categoria: int

class ProductoResponse(ProductoCreate):
    id_producto: int
    activo: bool
    fecha_creacion: datetime
    fecha_actualizacion: datetime
    
    class Config:
        from_attributes = True

# -------------------------------------------------------------------
# 4. INICIALIZACIÓN DE FASTAPI Y CORS
# -------------------------------------------------------------------
app = FastAPI(title="WS 2 - Gestión de Productos e Inventario (PostgreSQL)")

# ---- CONFIGURACIÓN DE IMÁGENES ----
# Asegurar que exista una carpeta llamada "uploads" en tu proyecto
os.makedirs("uploads", exist_ok=True)

# Montar la carpeta "uploads" para que las imágenes sean accesibles por URL
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
# ------------------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# -------------------------------------------------------------------
# 5. ENDPOINTS
# -------------------------------------------------------------------

# Endpoint para consultar todas las categorías (Usado en el menú desplegable de React)
@app.get("/categorias", response_model=List[CategoriaResponse])
def get_categorias(db: Session = Depends(get_db)):
    categorias = db.query(Categoria).all()
    return categorias

# Endpoint para crear una categoría
@app.post("/categorias", response_model=CategoriaResponse)
def create_categoria(categoria: CategoriaCreate, db: Session = Depends(get_db)):
    cat_existe = db.query(Categoria).filter(Categoria.nombre == categoria.nombre).first()
    if cat_existe:
        raise HTTPException(status_code=400, detail="Ya existe una categoría con ese nombre")

    nueva_categoria = Categoria(nombre=categoria.nombre)
    db.add(nueva_categoria)
    db.commit()
    db.refresh(nueva_categoria)
    return nueva_categoria

# HU07: Alta de un nuevo producto en el catálogo.
@app.post("/productos", response_model=ProductoResponse)
def create_producto(producto: ProductoCreate, db: Session = Depends(get_db)):
    categoria_existe = db.query(Categoria).filter(Categoria.id_categoria == producto.id_categoria).first()
    if not categoria_existe:
        raise HTTPException(status_code=404, detail="La categoría especificada no existe")

    if producto.precio < 0:
        raise HTTPException(status_code=400, detail="El precio no puede ser negativo")
    if producto.stock < 0:
        raise HTTPException(status_code=400, detail="El stock no puede ser negativo")

    nuevo_producto = Producto(
        nombre=producto.nombre,
        descripcion=producto.descripcion,
        precio=producto.precio,
        stock=producto.stock,
        url_imagen=producto.url_imagen,
        id_categoria=producto.id_categoria
    )
    db.add(nuevo_producto)
    db.commit()
    db.refresh(nuevo_producto)
    
    return nuevo_producto

# NUEVO ENDPOINT: Subir Imagen
@app.post("/upload-imagen")
async def upload_imagen(file: UploadFile = File(...)):
    file_location = f"uploads/{file.filename}"
    
    # Guardar el archivo en la carpeta "uploads"
    with open(file_location, "wb+") as file_object:
        shutil.copyfileobj(file.file, file_object)
        
    # Retornar la URL pública que usaremos en la base de datos (puerto 8000)
    url_publica = f"http://localhost:8000/uploads/{file.filename}"
    return {"url": url_publica}
# -------------------------------------------------------------------
# HU09: Consultar el detalle de los productos existentes (GET /productos)
# -------------------------------------------------------------------
@app.get("/productos", response_model=List[ProductoResponse])
def get_productos(db: Session = Depends(get_db)):
    # Consultamos todos los productos en la base de datos PostgreSQL
    productos = db.query(Producto).all()
    return productos
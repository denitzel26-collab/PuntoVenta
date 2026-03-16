// frontend/src/components/ProductManagement.jsx
import React, { useState, useEffect } from 'react';
import axios from 'axios';

const ProductManagement = () => {
  const [nombreCategoria, setNombreCategoria] = useState('');
  const [categorias, setCategorias] = useState([]); 
  
  // NUEVO ESTADO: Para guardar la lista de productos de la base de datos
  const [productos, setProductos] = useState([]);
  
  const [nuevoProducto, setNuevoProducto] = useState({
    nombre: '',
    descripcion: '',
    precio: '',
    stock: '',
    url_imagen: '',
    id_categoria: ''
  });

  const [mensaje, setMensaje] = useState('');
  const [error, setError] = useState('');
  const [uploading, setUploading] = useState(false);

  // Cargar categorías
  const fetchCategorias = async () => {
    try {
      const response = await axios.get('http://localhost:8000/categorias');
      setCategorias(response.data);
    } catch (err) {
      console.error("Error al cargar categorías", err);
    }
  };

  // NUEVA FUNCIÓN (HU09): Cargar productos
  const fetchProductos = async () => {
    try {
      const response = await axios.get('http://localhost:8000/productos');
      setProductos(response.data);
    } catch (err) {
      console.error("Error al cargar productos", err);
    }
  };

  // Se ejecutan ambas funciones al abrir la pantalla
  useEffect(() => {
    fetchCategorias();
    fetchProductos();
  }, []);

  const handleCrearCategoria = async (e) => {
    e.preventDefault();
    setMensaje('');
    setError('');
    try {
      const response = await axios.post('http://localhost:8000/categorias', { nombre: nombreCategoria });
      setMensaje(`Categoría '${response.data.nombre}' creada con éxito.`);
      setNombreCategoria('');
      fetchCategorias(); 
    } catch (err) {
      setError(err.response?.data?.detail || 'Error al crear la categoría.');
    }
  };

  const handleImageUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const formData = new FormData();
    formData.append("file", file);

    setUploading(true);
    setError('');
    
    try {
      const response = await axios.post('http://localhost:8000/upload-imagen', formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      setNuevoProducto({ ...nuevoProducto, url_imagen: response.data.url });
      setMensaje('¡Imagen subida y adjuntada correctamente!');
    } catch (err) {
      setError('Error al subir la imagen al servidor.');
    } finally {
      setUploading(false);
    }
  };

  const handleCrearProducto = async (e) => {
    e.preventDefault();
    setMensaje('');
    setError('');

    try {
      await axios.post('http://localhost:8000/productos', {
        nombre: nuevoProducto.nombre,
        descripcion: nuevoProducto.descripcion || null,
        precio: parseFloat(nuevoProducto.precio),
        stock: parseInt(nuevoProducto.stock),
        url_imagen: nuevoProducto.url_imagen || null,
        id_categoria: parseInt(nuevoProducto.id_categoria)
      });

      setMensaje('¡Producto registrado en el catálogo con éxito!');
      setNuevoProducto({ nombre: '', descripcion: '', precio: '', stock: '', url_imagen: '', id_categoria: '' });
      document.getElementById("inputFile").value = "";
      
      // Volvemos a pedir los productos para que la tabla se actualice sola
      fetchProductos();

    } catch (err) {
      setError(err.response?.data?.detail || 'Error al intentar registrar el producto.');
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setNuevoProducto({ ...nuevoProducto, [name]: value });
  };

  // Función auxiliar para traducir el "id_categoria" al "nombre" en la tabla
  const obtenerNombreCategoria = (id) => {
    const categoria = categorias.find(cat => cat.id_categoria === id);
    return categoria ? categoria.nombre : 'Desconocida';
  };

  return (
    <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
      <h1 style={{ color: '#333' }}>Gestión de Catálogo e Inventario</h1>

      {/* --- FORMULARIO CATEGORÍAS --- */}
      <div style={{ backgroundColor: '#e9ecef', padding: '15px', borderRadius: '8px', marginBottom: '20px' }}>
        <h3>Paso 1: Crear una Categoría</h3>
        <form onSubmit={handleCrearCategoria} style={{ display: 'flex', gap: '10px' }}>
          <input type="text" placeholder="Nueva categoría (ej. Laptops)" value={nombreCategoria} onChange={(e) => setNombreCategoria(e.target.value)} required style={{ padding: '8px', width: '250px' }} />
          <button type="submit" style={{ padding: '8px 15px', backgroundColor: '#6c757d', color: 'white', border: 'none', borderRadius: '4px', cursor:'pointer' }}>Crear y Añadir a la Lista</button>
        </form>
      </div>

      {/* --- FORMULARIO PRODUCTOS (HU07) --- */}
      <div style={{ backgroundColor: '#f9f9f9', padding: '20px', borderRadius: '8px', border: '1px solid #ddd' }}>
        <h2>HU07: Alta de Nuevo Producto</h2>
        <form onSubmit={handleCrearProducto} style={{ display: 'flex', gap: '15px', flexWrap: 'wrap', alignItems: 'flex-end' }}>
          <div style={{ display: 'flex', flexDirection: 'column', width: '100%', maxWidth: '400px' }}>
            <label>Nombre del Producto *:</label>
            <input type="text" name="nombre" value={nuevoProducto.nombre} onChange={handleInputChange} required style={{ padding: '8px' }} />
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', width: '100%', maxWidth: '400px' }}>
            <label>Descripción (Opcional):</label>
            <textarea name="descripcion" value={nuevoProducto.descripcion} onChange={handleInputChange} style={{ padding: '8px', height: '60px' }} />
          </div>
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            <label>Precio Unitario ($) *:</label>
            <input type="number" step="0.01" name="precio" value={nuevoProducto.precio} onChange={handleInputChange} required style={{ padding: '8px', width: '120px' }} min="0" />
          </div>
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            <label>Stock Inicial *:</label>
            <input type="number" name="stock" value={nuevoProducto.stock} onChange={handleInputChange} required style={{ padding: '8px', width: '120px' }} min="0" />
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', width: '100%', maxWidth: '300px' }}>
            <label>Cargar Imagen (Opcional):</label>
            <input id="inputFile" type="file" accept="image/*" onChange={handleImageUpload} style={{ padding: '5px' }} />
            {uploading && <span style={{ color: 'blue', fontSize: '12px' }}>Subiendo imagen...</span>}
            {nuevoProducto.url_imagen && (
              <div style={{ marginTop: '10px' }}>
                <span style={{ fontSize: '12px', color: 'green' }}>✓ Imagen lista</span><br/>
                <img src={nuevoProducto.url_imagen} alt="Vista previa" style={{ width: '80px', height: '80px', objectFit: 'cover', borderRadius: '4px', border: '1px solid #ccc' }} />
              </div>
            )}
          </div>
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            <label>Categoría *:</label>
            <select name="id_categoria" value={nuevoProducto.id_categoria} onChange={handleInputChange} required style={{ padding: '8px', width: '150px', cursor:'pointer' }}>
              <option value="">-- Selecciona --</option>
              {categorias.map((cat) => (
                <option key={cat.id_categoria} value={cat.id_categoria}>{cat.nombre}</option>
              ))}
            </select>
          </div>
          <div style={{ width: '100%', marginTop: '10px' }}>
            <button type="submit" disabled={uploading} style={{ padding: '10px 20px', backgroundColor: uploading ? '#ccc' : '#28a745', color: 'white', border: 'none', borderRadius: '4px', cursor: uploading ? 'not-allowed' : 'pointer' }}>Guardar Producto</button>
          </div>
        </form>
        {mensaje && <p style={{ color: 'green', fontWeight: 'bold', marginTop: '15px' }}>{mensaje}</p>}
        {error && <p style={{ color: 'red', fontWeight: 'bold', marginTop: '15px' }}>{error}</p>}
      </div>

      {/* --- TABLA DE PRODUCTOS (HU09) --- */}
      <div style={{ backgroundColor: '#fff', padding: '20px', borderRadius: '8px', border: '1px solid #ddd', marginTop: '30px' }}>
        <h2>HU09: Directorio de Productos Existentes</h2>
        <table style={{ width: '100%', borderCollapse: 'collapse', marginTop: '15px' }}>
          <thead>
            <tr style={{ backgroundColor: '#17a2b8', color: 'white', textAlign: 'left' }}>
              <th style={{ padding: '10px', border: '1px solid #ddd', textAlign: 'center' }}>Imagen</th>
              <th style={{ padding: '10px', border: '1px solid #ddd' }}>Nombre</th>
              <th style={{ padding: '10px', border: '1px solid #ddd' }}>Categoría</th>
              <th style={{ padding: '10px', border: '1px solid #ddd' }}>Precio ($)</th>
              <th style={{ padding: '10px', border: '1px solid #ddd' }}>Stock</th>
            </tr>
          </thead>
          <tbody>
            {productos.length > 0 ? (
              productos.map((prod) => (
                <tr key={prod.id_producto} style={{ borderBottom: '1px solid #ddd' }}>
                  
                  {/* Celda de la Imagen */}
                  <td style={{ padding: '10px', border: '1px solid #ddd', textAlign: 'center' }}>
                    {prod.url_imagen ? (
                      <img src={prod.url_imagen} alt={prod.nombre} style={{ width: '60px', height: '60px', objectFit: 'cover', borderRadius: '4px', border: '1px solid #ccc' }} />
                    ) : (
                      <span style={{ fontSize: '12px', color: '#999' }}>Sin foto</span>
                    )}
                  </td>

                  <td style={{ padding: '10px', border: '1px solid #ddd', fontWeight: 'bold' }}>{prod.nombre}</td>
                  
                  {/* Convertimos el ID en el Nombre real de la categoría */}
                  <td style={{ padding: '10px', border: '1px solid #ddd' }}>{obtenerNombreCategoria(prod.id_categoria)}</td>
                  
                  <td style={{ padding: '10px', border: '1px solid #ddd', color: 'green', fontWeight: 'bold' }}>${prod.precio}</td>
                  <td style={{ padding: '10px', border: '1px solid #ddd' }}>
                    {prod.stock} {prod.stock <= 5 && <span style={{color: 'red', fontSize: '12px'}}>(¡Bajo!)</span>}
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan="5" style={{ padding: '20px', textAlign: 'center', color: '#666' }}>No hay productos registrados aún en PostgreSQL.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

    </div>
  );
};

export default ProductManagement;
// frontend/src/components/ProductManagement.jsx
import React, { useState, useEffect } from 'react';
import axios from 'axios';

const ProductManagement = () => {
  const [categorias, setCategorias] = useState([]); 
  const [productos, setProductos] = useState([]);
  const [vistaActual, setVistaActual] = useState('catalogo'); 
  const [busqueda, setBusqueda] = useState('');
  
  // Estado inicial del formulario (Ahora incluye 'activo')
  const estadoInicialProducto = { nombre: '', descripcion: '', precio: '', stock: '', url_imagen: '', id_categoria: '', activo: true };
  const [nuevoProducto, setNuevoProducto] = useState(estadoInicialProducto);
  
  // ESTADOS PARA MODALES
  const [modalExito, setModalExito] = useState(false);
  const [modalEliminar, setModalEliminar] = useState({ visible: false, id: null, nombre: '' });
  const [modalEditar, setModalEditar] = useState(false);
  
  // --- NUEVOS ESTADOS PARA GESTIÓN DE CATEGORÍAS ---
  const [modalCategorias, setModalCategorias] = useState(false);
  const [nombreNuevaCategoria, setNombreNuevaCategoria] = useState('');
  const [categoriaEditando, setCategoriaEditando] = useState(null); // ID de la cat que se está editando
  const [nombreEdicionCat, setNombreEdicionCat] = useState('');

  const [error, setError] = useState('');
  const [uploading, setUploading] = useState(false);

  const fetchCategorias = async () => {
    try {
      const response = await axios.get('http://localhost:8000/categorias');
      setCategorias(response.data);
    } catch (err) { console.error("Error al cargar categorías", err); }
  };

  const fetchProductos = async () => {
    try {
      const response = await axios.get('http://localhost:8000/productos');
      setProductos(response.data);
    } catch (err) { console.error("Error al cargar productos", err); }
  };

  useEffect(() => {
    fetchCategorias();
    fetchProductos();
  }, []);

  const productosFiltrados = productos.filter(prod => 
    prod.nombre.toLowerCase().includes(busqueda.toLowerCase())
  );

  // -------------------------------------------------------------
  // FUNCIONES DE CATEGORÍAS (CREAR, EDITAR, ELIMINAR)
  // -------------------------------------------------------------
  const handleCrearCategoria = async (e) => {
    e.preventDefault();
    try {
      await axios.post('http://localhost:8000/categorias', { nombre: nombreNuevaCategoria });
      setNombreNuevaCategoria('');
      fetchCategorias(); 
    } catch (err) { alert(err.response?.data?.detail || 'Error al crear categoría'); }
  };

  const handleEliminarCategoria = async (id) => {
    if(!window.confirm("¿Seguro que deseas eliminar esta categoría?")) return;
    try {
      await axios.delete(`http://localhost:8000/categorias/${id}`);
      fetchCategorias();
    } catch (err) { 
      // Muestra el mensaje de protección de BD (si tiene productos asignados)
      alert(err.response?.data?.detail || "Error al eliminar."); 
    }
  };

  const guardarEdicionCategoria = async (id) => {
    try {
      await axios.put(`http://localhost:8000/categorias/${id}`, { nombre: nombreEdicionCat });
      setCategoriaEditando(null);
      fetchCategorias();
    } catch (err) { alert(err.response?.data?.detail || "Error al editar."); }
  };

  // -------------------------------------------------------------
  // FUNCIONES DE PRODUCTOS
  // -------------------------------------------------------------
  const handleImageUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const formData = new FormData();
    formData.append("file", file);
    setUploading(true);
    try {
      const response = await axios.post('http://localhost:8000/upload-imagen', formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      setNuevoProducto({ ...nuevoProducto, url_imagen: response.data.url });
    } catch (err) { alert('Error al subir la imagen.'); } 
    finally { setUploading(false); }
  };

  const handleGuardarProducto = async (e) => {
    e.preventDefault();
    setError('');
    try {
      const datosAEnviar = {
        ...nuevoProducto,
        precio: parseFloat(nuevoProducto.precio),
        stock: parseInt(nuevoProducto.stock),
        id_categoria: parseInt(nuevoProducto.id_categoria)
      };

      if (modalEditar) {
        await axios.put(`http://localhost:8000/productos/${nuevoProducto.id_producto}`, datosAEnviar);
        setModalEditar(false);
      } else {
        await axios.post('http://localhost:8000/productos', datosAEnviar);
      }
      
      setNuevoProducto(estadoInicialProducto);
      if(document.getElementById("inputFile")) document.getElementById("inputFile").value = "";
      fetchProductos();
      setModalExito(true); 
      
    } catch (err) { setError(err.response?.data?.detail || 'Error al guardar el producto.'); }
  };

  const confirmarEliminacion = async () => {
    try {
      await axios.delete(`http://localhost:8000/productos/${modalEliminar.id}`);
      setModalEliminar({ visible: false, id: null, nombre: '' });
      fetchProductos(); 
    } catch (err) { alert('Error al eliminar el producto'); }
  };

  // --- NUEVA: Botón rápido para encender/apagar producto desde la tarjeta ---
  const toggleActivoRapido = async (prod) => {
    try {
      const datosActualizados = { ...prod, activo: !prod.activo }; // Invertimos el estado
      await axios.put(`http://localhost:8000/productos/${prod.id_producto}`, datosActualizados);
      fetchProductos(); // Refrescamos
    } catch (err) { alert("Error al cambiar el estado del producto"); }
  };

  const abrirEdicion = (producto) => {
    setNuevoProducto({ ...producto }); 
    setModalEditar(true);
    setVistaActual('formulario');
  };

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    
    // Si es un checkbox, tomamos 'checked', si no, 'value'
    let nuevoValor = type === 'checkbox' ? checked : value;
    let nuevosDatos = { ...nuevoProducto, [name]: nuevoValor };

    // --- REGLA MÁGICA: Si stock es 0, lo desactivamos automáticamente ---
    if (name === 'stock' && parseInt(value) === 0) {
      nuevosDatos.activo = false;
    }

    setNuevoProducto(nuevosDatos);
  };

  const obtenerNombreCategoria = (id) => {
    const categoria = categorias.find(cat => cat.id_categoria === id);
    return categoria ? categoria.nombre : 'Desconocida';
  };

  return (
    <div style={{ backgroundColor: '#ebebf0', minHeight: '100vh', padding: '20px', fontFamily: 'Arial, sans-serif', position: 'relative' }}>
      
      {/* 1. MODAL DE CATEGORÍAS */}
      {modalCategorias && (
        <div style={{ position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh', backgroundColor: 'rgba(0,0,0,0.6)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 }}>
          <div style={{ backgroundColor: 'white', padding: '30px', borderRadius: '12px', width: '90%', maxWidth: '500px', maxHeight: '80vh', overflowY: 'auto' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '2px solid #eee', paddingBottom: '10px', marginBottom: '20px' }}>
              <h2 style={{ margin: 0 }}>Gestión de Categorías</h2>
              <button onClick={() => setModalCategorias(false)} style={{ background: 'none', border: 'none', fontSize: '20px', cursor: 'pointer' }}>✖</button>
            </div>
            
            {/* Formulario para añadir nueva */}
            <form onSubmit={handleCrearCategoria} style={{ display: 'flex', gap: '10px', marginBottom: '20px' }}>
              <input type="text" placeholder="Nueva categoría..." value={nombreNuevaCategoria} onChange={(e) => setNombreNuevaCategoria(e.target.value)} required style={{ flex: 1, padding: '10px', borderRadius: '4px', border: '1px solid #ccc' }} />
              <button type="submit" style={{ padding: '10px 20px', backgroundColor: '#28a745', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer', fontWeight: 'bold' }}>Añadir</button>
            </form>

            {/* Lista de categorías */}
            <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
              {categorias.map(cat => (
                <li key={cat.id_categoria} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px', borderBottom: '1px solid #eee', backgroundColor: '#f9f9f9', marginBottom: '5px', borderRadius: '4px' }}>
                  
                  {categoriaEditando === cat.id_categoria ? (
                    <div style={{ display: 'flex', gap: '5px', width: '100%' }}>
                      <input type="text" value={nombreEdicionCat} onChange={(e) => setNombreEdicionCat(e.target.value)} style={{ flex: 1, padding: '5px' }} />
                      <button onClick={() => guardarEdicionCategoria(cat.id_categoria)} style={{ background: '#3483fa', color: 'white', border: 'none', padding: '5px 10px', borderRadius: '3px', cursor: 'pointer' }}>Guardar</button>
                      <button onClick={() => setCategoriaEditando(null)} style={{ background: '#ccc', border: 'none', padding: '5px 10px', borderRadius: '3px', cursor: 'pointer' }}>Cancelar</button>
                    </div>
                  ) : (
                    <>
                      <span style={{ fontWeight: 'bold', color: '#333' }}>{cat.nombre}</span>
                      <div style={{ display: 'flex', gap: '5px' }}>
                        <button onClick={() => { setCategoriaEditando(cat.id_categoria); setNombreEdicionCat(cat.nombre); }} title="Editar Nombre" style={{ background: 'none', border: '1px solid #ccc', borderRadius: '4px', cursor: 'pointer', padding: '5px' }}>✏️</button>
                        <button onClick={() => handleEliminarCategoria(cat.id_categoria)} title="Eliminar" style={{ background: 'none', border: '1px solid #dc3545', borderRadius: '4px', cursor: 'pointer', padding: '5px' }}>🗑️</button>
                      </div>
                    </>
                  )}
                </li>
              ))}
            </ul>
          </div>
        </div>
      )}

      {/* 2. MODAL DE ÉXITO */}
      {modalExito && (
        <div style={{ position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh', backgroundColor: 'rgba(0,0,0,0.6)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 }}>
          <div style={{ backgroundColor: 'white', padding: '40px', borderRadius: '12px', textAlign: 'center', boxShadow: '0 4px 15px rgba(0,0,0,0.2)', maxWidth: '400px', width: '90%' }}>
            <div style={{ fontSize: '60px', color: '#28a745', marginBottom: '10px', lineHeight: '1' }}>✓</div>
            <h2 style={{ margin: '0 0 10px 0', color: '#333' }}>¡Operación Exitosa!</h2>
            <button onClick={() => { setModalExito(false); setVistaActual('catalogo'); }} style={{ padding: '12px 25px', backgroundColor: '#3483fa', color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer', width: '100%' }}>Volver al catálogo</button>
          </div>
        </div>
      )}

      {/* 3. MODAL CONFIRMAR ELIMINAR */}
      {modalEliminar.visible && (
        <div style={{ position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh', backgroundColor: 'rgba(0,0,0,0.6)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 }}>
          <div style={{ backgroundColor: 'white', padding: '30px', borderRadius: '12px', textAlign: 'center', boxShadow: '0 4px 15px rgba(0,0,0,0.2)', maxWidth: '400px', width: '90%' }}>
            <div style={{ fontSize: '50px', color: '#dc3545', marginBottom: '10px', lineHeight: '1' }}>⚠️</div>
            <h2 style={{ margin: '0 0 10px 0', color: '#333' }}>¿Eliminar Producto?</h2>
            <p style={{ color: '#666', fontSize: '16px', marginBottom: '25px' }}>Vas a eliminar <strong>"{modalEliminar.nombre}"</strong>. Esto no se puede deshacer.</p>
            <div style={{ display: 'flex', gap: '10px', justifyContent: 'center' }}>
              <button onClick={() => setModalEliminar({ visible: false, id: null, nombre: '' })} style={{ padding: '10px 20px', backgroundColor: '#ccc', color: '#333', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: 'bold' }}>Cancelar</button>
              <button onClick={confirmarEliminacion} style={{ padding: '10px 20px', backgroundColor: '#dc3545', color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: 'bold' }}>Sí, Eliminar</button>
            </div>
          </div>
        </div>
      )}

      {/* HEADER PRINCIPAL */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#ffe600', padding: '15px 20px', borderRadius: '8px', boxShadow: '0 1px 3px rgba(0,0,0,0.2)', marginBottom: '20px' }}>
        <h1 style={{ color: '#333', margin: 0, fontSize: '24px' }}>Catálogo de Productos</h1>
        
        {vistaActual === 'catalogo' ? (
          <div style={{ display: 'flex', gap: '15px', alignItems: 'center' }}>
            <input type="text" placeholder="Buscar productos..." value={busqueda} onChange={(e) => setBusqueda(e.target.value)} style={{ padding: '10px 15px', borderRadius: '20px', border: '1px solid #ccc', width: '300px', outline: 'none' }} />
            
            {/* NUEVO BOTÓN: GESTOR DE CATEGORÍAS */}
            <button onClick={() => setModalCategorias(true)} style={{ padding: '10px 15px', backgroundColor: '#3483fa', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer', fontWeight: 'bold' }}>
              📁 Categorías
            </button>
            
            <button onClick={() => { setNuevoProducto(estadoInicialProducto); setModalEditar(false); setVistaActual('formulario'); setError(''); }} style={{ padding: '10px 15px', backgroundColor: '#3483fa', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer', fontWeight: 'bold' }}>
              + Añadir Producto
            </button>
          </div>
        ) : (
          <button onClick={() => setVistaActual('catalogo')} style={{ padding: '10px 15px', backgroundColor: '#fff', color: '#3483fa', border: '1px solid #3483fa', borderRadius: '4px', cursor: 'pointer', fontWeight: 'bold' }}>
            ← Cancelar y Volver
          </button>
        )}
      </div>

      {/* CATÁLOGO O FORMULARIO */}
      {vistaActual === 'catalogo' ? (
        <div>
          {productosFiltrados.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '50px', color: '#666' }}><h3>No se encontraron productos.</h3></div>
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: '20px' }}>
              {productosFiltrados.map(prod => (
                <div key={prod.id_producto} style={{ 
                  backgroundColor: '#fff', borderRadius: '8px', overflow: 'hidden', 
                  boxShadow: '0 1px 2px rgba(0,0,0,0.1)', position: 'relative',
                  opacity: prod.activo ? 1 : 0.6 // EFECTO VISUAL: Opaco si está inactivo
                }}>
                  
                  {/* BADGE DE INACTIVO */}
                  {!prod.activo && (
                    <span style={{ position: 'absolute', top: '10px', left: '10px', backgroundColor: 'red', color: 'white', padding: '3px 8px', borderRadius: '4px', fontSize: '12px', fontWeight: 'bold', zIndex: 10 }}>Inactivo</span>
                  )}

                  <div style={{ position: 'absolute', top: '10px', right: '10px', display: 'flex', gap: '5px', zIndex: 10 }}>
                    <button onClick={() => abrirEdicion(prod)} title="Editar" style={{ backgroundColor: 'rgba(255,255,255,0.9)', border: '1px solid #ccc', borderRadius: '50%', width: '30px', height: '30px', cursor: 'pointer', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>✏️</button>
                    <button onClick={() => setModalEliminar({ visible: true, id: prod.id_producto, nombre: prod.nombre })} title="Eliminar" style={{ backgroundColor: 'rgba(255,255,255,0.9)', border: '1px solid #ccc', borderRadius: '50%', width: '30px', height: '30px', cursor: 'pointer', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>🗑️</button>
                  </div>

                  <div style={{ width: '100%', height: '200px', backgroundColor: '#f9f9f9', display: 'flex', justifyContent: 'center', alignItems: 'center', borderBottom: '1px solid #eee' }}>
                    {prod.url_imagen ? (
                      <img src={prod.url_imagen} alt={prod.nombre} style={{ maxWidth: '100%', maxHeight: '100%', objectFit: 'contain' }} />
                    ) : ( <span style={{ color: '#ccc' }}>Sin imagen</span> )}
                  </div>

                  <div style={{ padding: '15px' }}>
                    <p style={{ margin: '0 0 5px 0', fontSize: '22px', fontWeight: '400', color: '#333' }}>${prod.precio}</p>
                    <p style={{ margin: '0 0 10px 0', fontSize: '14px', color: '#666', lineHeight: '1.2', height: '34px', overflow: 'hidden' }}>{prod.nombre}</p>
                    
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '10px', fontSize: '12px' }}>
                      <span style={{ backgroundColor: '#e6f7ff', color: '#0050b3', padding: '2px 6px', borderRadius: '4px' }}>{obtenerNombreCategoria(prod.id_categoria)}</span>
                      <span style={{ color: prod.stock <= 5 ? 'red' : '#28a745', fontWeight: 'bold' }}>Stock: {prod.stock}</span>
                    </div>

                    {/* BOTÓN PARA ACTIVAR/DESACTIVAR RÁPIDO */}
                    <button 
                      onClick={() => toggleActivoRapido(prod)}
                      style={{ width: '100%', marginTop: '15px', padding: '8px', border: '1px solid #ccc', backgroundColor: prod.activo ? '#f8f9fa' : '#28a745', color: prod.activo ? '#333' : 'white', borderRadius: '4px', cursor: 'pointer', fontSize: '12px', fontWeight: 'bold' }}>
                      {prod.activo ? 'Desactivar (Pausar)' : 'Activar Producto'}
                    </button>

                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      ) : (
        <div style={{ maxWidth: '800px', margin: '0 auto', backgroundColor: '#fff', padding: '30px', borderRadius: '8px', boxShadow: '0 2px 4px rgba(0,0,0,0.1)' }}>
          <h2 style={{ borderBottom: '2px solid #eee', paddingBottom: '10px', marginBottom: '20px' }}>
            {modalEditar ? 'Editar Producto Existente' : 'Registrar Nuevo Producto'}
          </h2>
          
          <form onSubmit={handleGuardarProducto} style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
            
            {/* NUEVO: CHECKBOX DE ACTIVO EN EL FORMULARIO */}
            <div style={{ padding: '10px', backgroundColor: nuevoProducto.activo ? '#e6f7ff' : '#ffe6e6', borderRadius: '4px', display: 'inline-block', width: 'max-content' }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', fontWeight: 'bold', color: nuevoProducto.activo ? '#0050b3' : '#cc0000' }}>
                <input type="checkbox" name="activo" checked={nuevoProducto.activo} onChange={handleInputChange} style={{ width: '18px', height: '18px' }} />
                {nuevoProducto.activo ? 'El producto está ACTIVO (Visible en tienda)' : 'El producto está INACTIVO (Oculto en tienda)'}
              </label>
            </div>

            <div style={{ display: 'flex', gap: '15px' }}>
              <div style={{ flex: 2, display: 'flex', flexDirection: 'column' }}>
                <label>Nombre del Producto *:</label>
                <input type="text" name="nombre" value={nuevoProducto.nombre} onChange={handleInputChange} required style={{ padding: '10px', borderRadius: '4px', border: '1px solid #ccc' }} />
              </div>
              <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
                <label>Categoría *:</label>
                <select name="id_categoria" value={nuevoProducto.id_categoria} onChange={handleInputChange} required style={{ padding: '10px', borderRadius: '4px', border: '1px solid #ccc', cursor:'pointer' }}>
                  <option value="">-- Selecciona --</option>
                  {categorias.map((cat) => (
                    <option key={cat.id_categoria} value={cat.id_categoria}>{cat.nombre}</option>
                  ))}
                </select>
              </div>
            </div>

            <div style={{ display: 'flex', gap: '15px' }}>
              <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
                <label>Precio Unitario ($) *:</label>
                <input type="number" step="0.01" name="precio" value={nuevoProducto.precio} onChange={handleInputChange} required style={{ padding: '10px', borderRadius: '4px', border: '1px solid #ccc' }} min="0" />
              </div>
              <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
                <label>Stock * (Si pones 0, se desactivará):</label>
                <input type="number" name="stock" value={nuevoProducto.stock} onChange={handleInputChange} required style={{ padding: '10px', borderRadius: '4px', border: '1px solid #ccc' }} min="0" />
              </div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column' }}>
              <label>Descripción (Opcional):</label>
              <textarea name="descripcion" value={nuevoProducto.descripcion} onChange={handleInputChange} style={{ padding: '10px', borderRadius: '4px', border: '1px solid #ccc', height: '80px', resize: 'vertical' }} />
            </div>

            <div style={{ display: 'flex', flexDirection: 'column' }}>
              <label>{modalEditar ? 'Cambiar Imagen (Opcional):' : 'Cargar Imagen (Opcional):'}</label>
              <div style={{ display: 'flex', alignItems: 'center', gap: '15px' }}>
                <input id="inputFile" type="file" accept="image/*" onChange={handleImageUpload} style={{ padding: '5px' }} />
                {uploading && <span style={{ color: '#3483fa', fontSize: '14px' }}>Subiendo...</span>}
                {nuevoProducto.url_imagen && <img src={nuevoProducto.url_imagen} alt="Vista previa" style={{ width: '50px', height: '50px', objectFit: 'cover', borderRadius: '4px', border: '1px solid #ccc' }} />}
              </div>
            </div>

            <button type="submit" disabled={uploading} style={{ padding: '15px', backgroundColor: uploading ? '#ccc' : (modalEditar ? '#ffc107' : '#3483fa'), color: modalEditar ? '#333' : 'white', border: 'none', borderRadius: '4px', cursor: uploading ? 'not-allowed' : 'pointer', fontSize: '16px', fontWeight: 'bold', marginTop: '10px' }}>
              {modalEditar ? 'Actualizar Producto' : 'Guardar Producto'}
            </button>
          </form>
          {error && <p style={{ color: '#dc3545', fontWeight: 'bold', marginTop: '15px', textAlign: 'center' }}>{error}</p>}
        </div>
      )}
    </div>
  );
};

export default ProductManagement;
// frontend/src/components/UserManagement.jsx
import React, { useState, useEffect } from 'react';
import axios from 'axios';

const UserManagement = () => {
  const [usuarios, setUsuarios] = useState([]);
  
  const [formData, setFormData] = useState({
    Username: '',
    Password: '',
    Role: 'Vendedor'
  });
  
  // Estado para saber si estamos editando un usuario existente o creando uno nuevo
  const [editingUserId, setEditingUserId] = useState(null);
  
  const [mensaje, setMensaje] = useState('');
  const [error, setError] = useState('');

  // Cargar lista de usuarios (HU03)
  const fetchUsuarios = async () => {
    try {
      const response = await axios.get('http://localhost:3000/usuarios');
      setUsuarios(response.data);
    } catch (err) {
      setError('Error al cargar la lista de usuarios.');
    }
  };

  useEffect(() => {
    fetchUsuarios();
  }, []);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
  };

  // Guardar (Crear HU02 o Actualizar HU04/HU06)
  const handleSubmit = async (e) => {
    e.preventDefault();
    setMensaje('');
    setError('');

    try {
      if (editingUserId) {
        // MODO EDICIÓN (PUT)
        await axios.put(`http://localhost:3000/usuarios/${editingUserId}`, formData);
        setMensaje('¡Usuario actualizado con éxito!');
      } else {
        // MODO CREACIÓN (POST)
        await axios.post('http://localhost:3000/usuarios', formData);
        setMensaje('¡Usuario registrado con éxito!');
      }
      
      // Limpiar formulario y recargar lista
      cancelEdit();
      fetchUsuarios();
      
    } catch (err) {
      setError(err.response?.data?.message || 'Error al procesar la solicitud.');
    }
  };

  // Preparar el formulario para editar
  const handleEdit = (user) => {
    setEditingUserId(user._id);
    setFormData({
      Username: user.Username,
      Password: '', // Se deja en blanco, si el admin no escribe nada, no se actualiza
      Role: user.Role
    });
    setMensaje('');
    setError('');
  };

  // Cancelar la edición y limpiar el formulario
  const cancelEdit = () => {
    setEditingUserId(null);
    setFormData({ Username: '', Password: '', Role: 'Vendedor' });
  };

  // HU05: Eliminar usuario
  const handleDelete = async (id) => {
    // Confirmación nativa del navegador por seguridad
    const confirmacion = window.confirm("¿Estás seguro de que deseas dar de baja a este usuario de forma definitiva?");
    if (!confirmacion) return;

    setMensaje('');
    setError('');

    try {
      await axios.delete(`http://localhost:3000/usuarios/${id}`);
      setMensaje('Usuario eliminado correctamente.');
      fetchUsuarios(); // Recargar la tabla
    } catch (err) {
      setError('Error al intentar eliminar el usuario.');
    }
  };

  return (
    <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
      <h1 style={{ color: '#333' }}>Panel de Administración de Usuarios</h1>

      {/* FORMULARIO DE ALTA / EDICIÓN */}
      <div style={{ backgroundColor: '#f9f9f9', padding: '20px', borderRadius: '8px', marginBottom: '30px', border: '1px solid #ddd' }}>
        <h2>{editingUserId ? 'Editar Usuario Existente' : 'Registrar Nuevo Usuario'}</h2>
        
        <form onSubmit={handleSubmit} style={{ display: 'flex', gap: '15px', flexWrap: 'wrap', alignItems: 'flex-end' }}>
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            <label>Nombre de Usuario:</label>
            <input 
              type="text" 
              name="Username" 
              value={formData.Username} 
              onChange={handleInputChange} 
              required 
              style={{ padding: '8px', width: '200px' }}
            />
          </div>

          <div style={{ display: 'flex', flexDirection: 'column' }}>
            <label>{editingUserId ? 'Nueva Contraseña (opcional):' : 'Contraseña:'}</label>
            <input 
              type="password" 
              name="Password" 
              value={formData.Password} 
              onChange={handleInputChange} 
              required={!editingUserId} // Solo es obligatoria si es un usuario nuevo
              style={{ padding: '8px', width: '200px' }}
            />
          </div>

          <div style={{ display: 'flex', flexDirection: 'column' }}>
            <label>Rol Asignado:</label>
            <select 
              name="Role" 
              value={formData.Role} 
              onChange={handleInputChange}
              style={{ padding: '8px', width: '150px' }}
            >
              <option value="Vendedor">Vendedor</option>
              <option value="Administrador">Administrador</option>
              <option value="Consultor">Consultor</option>
            </select>
          </div>

          <button type="submit" style={{ padding: '10px 20px', backgroundColor: editingUserId ? '#ffc107' : '#28a745', color: '#000', border: 'none', borderRadius: '4px', cursor: 'pointer', fontWeight: 'bold' }}>
            {editingUserId ? 'Actualizar Cambios' : 'Guardar Usuario'}
          </button>

          {editingUserId && (
            <button type="button" onClick={cancelEdit} style={{ padding: '10px 20px', backgroundColor: '#6c757d', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer' }}>
              Cancelar
            </button>
          )}
        </form>
        
        {mensaje && <p style={{ color: 'green', fontWeight: 'bold', marginTop: '15px' }}>{mensaje}</p>}
        {error && <p style={{ color: 'red', fontWeight: 'bold', marginTop: '15px' }}>{error}</p>}
      </div>

      {/* LISTADO DE USUARIOS CON BOTONES DE ACCIÓN */}
      <div style={{ backgroundColor: '#fff', padding: '20px', borderRadius: '8px', border: '1px solid #ddd' }}>
        <h2>Directorio de Usuarios Existentes</h2>
        <table style={{ width: '100%', borderCollapse: 'collapse', marginTop: '15px' }}>
          <thead>
            <tr style={{ backgroundColor: '#007bff', color: 'white', textAlign: 'left' }}>
              <th style={{ padding: '10px', border: '1px solid #ddd' }}>Usuario</th>
              <th style={{ padding: '10px', border: '1px solid #ddd' }}>Rol</th>
              <th style={{ padding: '10px', border: '1px solid #ddd', textAlign: 'center' }}>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {usuarios.length > 0 ? (
              usuarios.map((user) => (
                <tr key={user._id} style={{ borderBottom: '1px solid #ddd' }}>
                  <td style={{ padding: '10px', border: '1px solid #ddd', fontWeight: 'bold' }}>{user.Username}</td>
                  <td style={{ padding: '10px', border: '1px solid #ddd' }}>{user.Role}</td>
                  <td style={{ padding: '10px', border: '1px solid #ddd', textAlign: 'center' }}>
                    
                    {/* Botón Editar (HU04 / HU06) */}
                    <button 
                      onClick={() => handleEdit(user)} 
                      style={{ marginRight: '10px', padding: '5px 10px', backgroundColor: '#ffc107', border: 'none', borderRadius: '3px', cursor: 'pointer' }}
                    >
                      Editar
                    </button>

                    {/* Botón Eliminar (HU05) */}
                    <button 
                      onClick={() => handleDelete(user._id)} 
                      style={{ padding: '5px 10px', backgroundColor: '#dc3545', color: 'white', border: 'none', borderRadius: '3px', cursor: 'pointer' }}
                    >
                      Eliminar
                    </button>

                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan="3" style={{ padding: '20px', textAlign: 'center' }}>No hay usuarios registrados aún.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default UserManagement;
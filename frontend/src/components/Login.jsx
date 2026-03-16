// frontend/src/components/Login.jsx
import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

const Login = () => {
  const [user, setUser] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    setError(''); // Limpiar errores previos

    try {
      // Consumo del WS 1 (Backend Node.js) [cite: 30, 31]
      const response = await axios.post('http://localhost:3000/auth/login', {
        user,
        password
      });

      // Guardar el token y el rol en el almacenamiento local
      localStorage.setItem('token', response.data.token);
      localStorage.setItem('role', response.data.role);

      // Lógica de redirección según el rol [cite: 6, 7, 26]
      if (response.data.role === 'Vendedor') {
          navigate('/ventas'); // Acceso a herramientas de venta 
      } else if (response.data.role === 'Administrador') {
          navigate('/admin-dashboard');
      } else {
          navigate('/reportes');
      }

    } catch (err) {
      setError(err.response?.data?.message || 'Error al conectar con el servidor');
    }
  };

  return (
    <div className="login-container" style={{ maxWidth: '400px', margin: 'auto', padding: '20px' }}>
      <h2>Iniciar Sesión</h2>
      <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
        <div>
          <label htmlFor="user">Usuario:</label>
          <input 
            type="text" 
            id="user"
            value={user} 
            onChange={(e) => setUser(e.target.value)} 
            required 
            style={{ width: '100%', padding: '8px' }}
          />
        </div>
        <div>
          <label htmlFor="password">Contraseña:</label>
          <input 
            type="password" 
            id="password"
            value={password} 
            onChange={(e) => setPassword(e.target.value)} 
            required 
            style={{ width: '100%', padding: '8px' }}
          />
        </div>
        
        {error && <div style={{ color: 'red', fontWeight: 'bold' }}>{error}</div>}
        
        <button type="submit" style={{ padding: '10px', backgroundColor: '#007bff', color: 'white', border: 'none' }}>
          Ingresar
        </button>
      </form>
    </div>
  );
};

export default Login;
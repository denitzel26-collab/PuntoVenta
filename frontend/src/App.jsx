import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Login from "./components/Login";
import UserManagement from "./components/UserManagement";
import ProductManagement from "./components/ProductManagement"; // NUEVO

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Login />} />
        <Route path="/admin-usuarios" element={<UserManagement />} /> 
        <Route path="/admin-productos" element={<ProductManagement />} /> {/* NUEVO */}
      </Routes>
    </Router>
  );
}

export default App;
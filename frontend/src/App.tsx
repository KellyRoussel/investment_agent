import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from '@contexts/AuthContext';
import { ProtectedRoute } from '@components/auth/ProtectedRoute';
import { Layout } from '@components/layout/Layout';
import { Login } from '@pages/Login';
import { Signup } from '@pages/Signup';
import { Profile } from '@pages/Profile';
import { Investments } from '@pages/Investments';
import { Portfolio } from '@pages/Portfolio';

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* Public routes */}
          <Route path="/login" element={<Login />} />
          <Route path="/signup" element={<Signup />} />

          {/* Protected routes with layout */}
          <Route element={<ProtectedRoute />}>
            <Route element={<Layout />}>
              <Route path="/portfolio" element={<Portfolio />} />
              <Route path="/investments" element={<Investments />} />
              <Route path="/profile" element={<Profile />} />
              <Route path="/" element={<Navigate to="/portfolio" replace />} />
            </Route>
          </Route>

          {/* Catch all - redirect to home */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;

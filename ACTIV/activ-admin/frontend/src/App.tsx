import { Component, type ReactElement, type ReactNode } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, NavLink, useNavigate } from 'react-router-dom';
import {
  Bell,
  BookOpen,
  Calendar,
  CreditCard,
  Flag,
  History,
  LayoutDashboard,
  LifeBuoy,
  LogOut,
  MapPin,
  MonitorCog,
  Settings,
  Tags,
  Users,
  Zap,
} from 'lucide-react';
import LoginScreen from './screens/LoginScreen';
import DashboardScreen from './screens/DashboardScreen';
import BookingsScreen from './screens/BookingsScreen';
import UsersScreen from './screens/UsersScreen';
import VenuesScreen from './screens/VenuesScreen';
import PaymentsScreen from './screens/PaymentsScreen';
import SupportScreen from './screens/SupportScreen';
import CatalogScreen from './screens/CatalogScreen';
import SettingsScreen from './screens/SettingsScreen';
import WebsiteAdminScreen from './screens/WebsiteAdminScreen';
import './App.css';

class AppErrorBoundary extends Component<{ children: ReactNode }, { error: Error | null }> {
  state: { error: Error | null } = { error: null };

  static getDerivedStateFromError(error: Error) {
    return { error };
  }

  render() {
    if (this.state.error) {
      return (
        <div className="auth-wrapper">
          <div className="glass-card app-error-card">
            <h1>Admin panel could not load</h1>
            <p>{this.state.error.message || 'Unexpected frontend error'}</p>
            <button className="btn btn-primary" type="button" onClick={() => window.location.reload()}>
              Reload
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

const ProtectedRoute = ({ children }: { children: ReactElement }) => {
  const token = localStorage.getItem('admin_access_token');
  if (!token) return <Navigate to="/login" replace />;
  return children;
};

const Sidebar = () => {
  const navigate = useNavigate();
  const handleLogout = () => {
    localStorage.removeItem('admin_access_token');
    localStorage.removeItem('admin_refresh_token');
    localStorage.removeItem('admin_email');
    navigate('/login');
  };

  return (
    <div className="sidebar">
      <div className="sidebar-header">
        <Zap className="brand-mark" size={24} fill="currentColor" />
        <div>
          <div className="brand-title">ACTIV</div>
          <span className="brand-subtitle">Admin Panel</span>
        </div>
      </div>
      <div className="nav-list">
        <NavLink to="/dashboard" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
          <LayoutDashboard size={20} /> Dashboard
        </NavLink>
        <NavLink to="/website-admin" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
          <MonitorCog size={20} /> Website Admin
        </NavLink>
        <NavLink to="/users" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
          <Users size={20} /> Users
        </NavLink>
        <NavLink to="/bookings" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
          <Calendar size={20} /> Bookings
        </NavLink>
        <NavLink to="/venues" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
          <MapPin size={20} /> Venues
        </NavLink>
        <NavLink to="/payments" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
          <CreditCard size={20} /> Payments
        </NavLink>
        <NavLink to="/coupons" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
          <Tags size={20} /> Coupons
        </NavLink>
        <NavLink to="/support" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
          <LifeBuoy size={20} /> Support
        </NavLink>
        <NavLink to="/content" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
          <BookOpen size={20} /> Content
        </NavLink>
        <NavLink to="/notifications" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
          <Bell size={20} /> Notifications
        </NavLink>
        <NavLink to="/audit-logs" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
          <History size={20} /> Audit Logs
        </NavLink>
        <NavLink to="/feature-flags" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
          <Flag size={20} /> Feature Flags
        </NavLink>
        <NavLink to="/settings" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
          <Settings size={20} /> Settings
        </NavLink>
      </div>
      <div className="sidebar-footer">
        <button className="btn" style={{ width: '100%' }} onClick={handleLogout}>
          <LogOut size={18} /> Logout
        </button>
      </div>
    </div>
  );
};

const Layout = ({ children }: { children: ReactElement }) => {
  return (
    <div className="layout-container">
      <Sidebar />
      <div className="main-content">
        <div className="topbar">
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', fontWeight: 500 }}>
            Admin Portal
          </div>
        </div>
        <div className="page-content">
          {children}
        </div>
      </div>
    </div>
  );
};

function App() {
  return (
    <AppErrorBoundary>
      <Router>
        <Routes>
          <Route path="/login" element={<LoginScreen />} />
          <Route path="/dashboard" element={<ProtectedRoute><Layout><DashboardScreen /></Layout></ProtectedRoute>} />
          <Route path="/website-admin" element={<ProtectedRoute><Layout><WebsiteAdminScreen /></Layout></ProtectedRoute>} />
          <Route path="/users" element={<ProtectedRoute><Layout><UsersScreen /></Layout></ProtectedRoute>} />
          <Route path="/bookings" element={<ProtectedRoute><Layout><BookingsScreen /></Layout></ProtectedRoute>} />
          <Route path="/venues" element={<ProtectedRoute><Layout><VenuesScreen /></Layout></ProtectedRoute>} />
          <Route path="/payments" element={<ProtectedRoute><Layout><PaymentsScreen /></Layout></ProtectedRoute>} />
          <Route path="/support" element={<ProtectedRoute><Layout><SupportScreen /></Layout></ProtectedRoute>} />
          <Route path="/catalog" element={<ProtectedRoute><Layout><CatalogScreen /></Layout></ProtectedRoute>} />
          <Route path="/coupons" element={<ProtectedRoute><Layout><CatalogScreen /></Layout></ProtectedRoute>} />
          <Route path="/content" element={<ProtectedRoute><Layout><CatalogScreen /></Layout></ProtectedRoute>} />
          <Route path="/notifications" element={<ProtectedRoute><Layout><SupportScreen /></Layout></ProtectedRoute>} />
          <Route path="/audit-logs" element={<ProtectedRoute><Layout><SettingsScreen /></Layout></ProtectedRoute>} />
          <Route path="/feature-flags" element={<ProtectedRoute><Layout><SettingsScreen /></Layout></ProtectedRoute>} />
          <Route path="/settings" element={<ProtectedRoute><Layout><SettingsScreen /></Layout></ProtectedRoute>} />
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </Router>
    </AppErrorBoundary>
  );
}

export default App;

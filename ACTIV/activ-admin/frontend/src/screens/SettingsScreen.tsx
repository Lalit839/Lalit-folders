export default function SettingsScreen() {
  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">Settings</h1>
      </div>
      
      <div className="glass-card settings-card">
        <h2 style={{ fontSize: '20px', marginBottom: '20px' }}>Admin Profile</h2>
        <div style={{ marginBottom: '20px' }}>
          <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>Email Address</label>
          <input className="input-control" type="email" value="super@activ.com" disabled />
        </div>
        <div style={{ marginBottom: '20px' }}>
          <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>Role</label>
          <input className="input-control" type="text" value="SUPER_ADMIN" disabled />
        </div>
        
        <hr className="settings-divider" />
        
        <h2 style={{ fontSize: '20px', marginBottom: '20px' }}>Preferences</h2>
        <div className="setting-row">
          <input type="checkbox" id="notif" defaultChecked />
          <label htmlFor="notif" style={{ fontWeight: 500 }}>Receive Email Notifications</label>
        </div>
        <div className="setting-row">
          <input type="checkbox" id="dark" />
          <label htmlFor="dark" style={{ fontWeight: 500 }}>Dark Mode</label>
        </div>

        <button className="btn btn-primary" style={{ marginTop: '30px' }} onClick={() => alert('Saved successfully!')}>Save Changes</button>
      </div>
    </div>
  );
}

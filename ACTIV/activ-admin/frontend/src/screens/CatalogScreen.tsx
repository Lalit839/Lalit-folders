import { useEffect, useState } from 'react';
import { AdminApi } from '../apiClient';

export default function CatalogScreen() {
  const [coupons, setCoupons] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadCatalog();
  }, []);

  const loadCatalog = async () => {
    try {
      setLoading(true);
      const res = await AdminApi.getCoupons();
      setCoupons(res.items);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Catalog (Coupons)</h1>
          <p style={{ color: 'var(--text-muted)' }}>Manage your promotional codes</p>
        </div>
      </div>

      <div className="stat-grid" style={{ marginBottom: '24px' }}>
        {loading ? (
          <div style={{ padding: '40px', width: '100%', textAlign: 'center' }}>Loading...</div>
        ) : (
          coupons.map(c => (
            <div key={c.id} className="glass-card stat-card" style={{ borderLeft: c.status === 'ACTIVE' ? '4px solid var(--success)' : '4px solid var(--danger)' }}>
              <span className="label" style={{ fontSize: '18px', color: '#fff' }}>{c.code}</span>
              <span style={{ fontSize: '14px', marginBottom: '10px', color: 'var(--text-muted)' }}>
                {c.percentOff ? `${c.percentOff}% OFF` : `₹${parseInt(c.amountOffPaise) / 100} OFF`}
              </span>
              <span className="badge" style={{ alignSelf: 'flex-start', background: c.status === 'ACTIVE' ? 'var(--success)' : 'var(--danger)', color: '#fff' }}>
                {c.status}
              </span>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

import { useEffect, useState } from 'react';
import { AdminApi } from '../apiClient';

export default function PaymentsScreen() {
  const [payments, setPayments] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadPayments();
  }, [page]);

  const loadPayments = async () => {
    try {
      setLoading(true);
      const res = await AdminApi.getPayments({ page, limit: 15 });
      setPayments(res.items);
      setTotal(res.total);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch(status) {
      case 'CAPTURED': return 'var(--success)';
      case 'CREATED': return 'var(--warning)';
      case 'FAILED': return 'var(--danger)';
      case 'REFUNDED': return 'var(--text-muted)';
      default: return 'var(--primary)';
    }
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Payments</h1>
          <p style={{ color: 'var(--text-muted)' }}>{total} total payments</p>
        </div>
      </div>

      <div className="glass-card table-wrapper">
        {loading ? (
          <div style={{ padding: '40px', textAlign: 'center' }}>Loading...</div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Booking Code</th>
                <th>Provider ID</th>
                <th>Amount</th>
                <th>Status</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {payments.map(p => (
                <tr key={p.id}>
                  <td style={{ fontWeight: 500 }}>{p.booking.publicCode}</td>
                  <td>{p.providerPaymentId || '—'}</td>
                  <td style={{ fontWeight: 600 }}>₹{(parseInt(p.amountPaise) / 100).toLocaleString('en-IN')}</td>
                  <td>
                    <span className="badge" style={{ background: getStatusColor(p.status), color: '#fff' }}>
                      {p.status}
                    </span>
                  </td>
                  <td>{new Date(p.createdAt).toLocaleDateString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
      
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '20px', gap: '10px' }}>
        <button className="btn" disabled={page === 1} onClick={() => setPage(p => p - 1)}>Previous</button>
        <button className="btn" disabled={payments.length < 15} onClick={() => setPage(p => p + 1)}>Next</button>
      </div>
    </div>
  );
}

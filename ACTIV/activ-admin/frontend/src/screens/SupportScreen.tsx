import { useEffect, useState } from 'react';
import { AdminApi } from '../apiClient';

export default function SupportScreen() {
  const [tickets, setTickets] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadTickets();
  }, [page]);

  const loadTickets = async () => {
    try {
      setLoading(true);
      const res = await AdminApi.getSupportTickets({ page, limit: 15 });
      setTickets(res.items);
      setTotal(res.total);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (ticketId: string, newStatus: string) => {
    try {
      await AdminApi.updateTicketStatus(ticketId, newStatus);
      loadTickets();
    } catch (e) {
      alert('Failed to update status');
    }
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Support Tickets</h1>
          <p style={{ color: 'var(--text-muted)' }}>{total} tickets</p>
        </div>
      </div>

      <div className="glass-card table-wrapper">
        {loading ? (
          <div style={{ padding: '40px', textAlign: 'center' }}>Loading...</div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Subject</th>
                <th>User</th>
                <th>Booking Code</th>
                <th>Status</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {tickets.map(t => (
                <tr key={t.id}>
                  <td style={{ fontWeight: 500 }}>{t.subject}</td>
                  <td>{t.user.name || t.user.phoneE164}</td>
                  <td>{t.booking?.publicCode || '—'}</td>
                  <td>
                    <select 
                      className="input-control" 
                      style={{ padding: '6px 10px', fontSize: '13px', width: 'auto' }}
                      value={t.status}
                      onChange={(e) => handleStatusChange(t.id, e.target.value)}
                    >
                      <option value="OPEN">OPEN</option>
                      <option value="IN_PROGRESS">IN_PROGRESS</option>
                      <option value="RESOLVED">RESOLVED</option>
                      <option value="CLOSED">CLOSED</option>
                    </select>
                  </td>
                  <td>{new Date(t.createdAt).toLocaleDateString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
      
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '20px', gap: '10px' }}>
        <button className="btn" disabled={page === 1} onClick={() => setPage(p => p - 1)}>Previous</button>
        <button className="btn" disabled={tickets.length < 15} onClick={() => setPage(p => p + 1)}>Next</button>
      </div>
    </div>
  );
}

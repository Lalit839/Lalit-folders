import { useEffect, useMemo, useState } from 'react';
import {
  Activity,
  Building2,
  CalendarDays,
  Headphones,
  IndianRupee,
  ReceiptIndianRupee,
  ShieldCheck,
  UserCheck,
  Users,
  WalletCards,
} from 'lucide-react';
import { AdminApi } from '../apiClient';
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

type DashboardState = {
  overview: any;
  revenueData: Array<{ date: string; revenue: number }>;
  bookingStatusData: Array<{ status: string; count: number }>;
  recentBookings: any[];
  users: any[];
  venues: any[];
  refunds: any[];
  tickets: any[];
};

const emptyDashboard: DashboardState = {
  overview: null,
  revenueData: [],
  bookingStatusData: [],
  recentBookings: [],
  users: [],
  venues: [],
  refunds: [],
  tickets: [],
};

const moneyFromPaise = (value: unknown) => {
  const amount = Number.parseInt(String(value ?? '0'), 10);
  return Number.isFinite(amount) ? amount / 100 : 0;
};

const formatMoney = (value: number) => `₹${value.toLocaleString('en-IN')}`;

const getTokenEmail = () => {
  const storedEmail = localStorage.getItem('admin_email');
  if (storedEmail) return storedEmail;

  const token = localStorage.getItem('admin_access_token');
  const payload = token?.split('.')[1];
  if (!payload) return 'Signed-in admin';

  try {
    const decoded = JSON.parse(atob(payload.replace(/-/g, '+').replace(/_/g, '/')));
    const fallback = decoded.email || decoded.username || decoded.name || decoded.sub || decoded.userId;
    if (!fallback || /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(String(fallback))) {
      return 'Signed-in admin';
    }
    return fallback;
  } catch {
    return 'Signed-in admin';
  }
};

export default function DashboardScreen() {
  const [dashboard, setDashboard] = useState<DashboardState>(emptyDashboard);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const loadData = async () => {
      try {
        setLoading(true);
        setError(null);

        const [
          overviewResult,
          revenueResult,
          bookingStatusResult,
          bookingsResult,
          usersResult,
          venuesResult,
          refundsResult,
          ticketsResult,
        ] = await Promise.allSettled([
          AdminApi.getDashboardOverview(),
          AdminApi.getDashboardRevenue(30),
          AdminApi.getDashboardBookings(30),
          AdminApi.getBookings({ page: 1, limit: 6 }),
          AdminApi.getUsers({ page: 1, limit: 100 }),
          AdminApi.getVenues({ page: 1, limit: 100 }),
          AdminApi.getRefunds({ page: 1, limit: 100 }),
          AdminApi.getSupportTickets({ page: 1, limit: 100 }),
        ]);

        const overview = overviewResult.status === 'fulfilled' ? overviewResult.value : null;
        const revenue = revenueResult.status === 'fulfilled' ? revenueResult.value : [];
        const bookingStatus = bookingStatusResult.status === 'fulfilled' ? bookingStatusResult.value : [];
        const bookings = bookingsResult.status === 'fulfilled' ? bookingsResult.value.items : [];
        const users = usersResult.status === 'fulfilled' ? usersResult.value.items : [];
        const venues = venuesResult.status === 'fulfilled' ? venuesResult.value.items : [];
        const refunds = refundsResult.status === 'fulfilled' ? refundsResult.value.items : [];
        const tickets = ticketsResult.status === 'fulfilled' ? ticketsResult.value.items : [];

        const revenueData = revenue.map((item: any) => ({
          date: new Date(item.day || item.date || item.createdAt).toISOString().substring(5, 10),
          revenue: moneyFromPaise(item.revenuePaise ?? item.amountPaise ?? item.totalPaise),
        }));

        const bookingStatusData = bookingStatus.map((item: any) => ({
          status: item.status || item.bookingStatus || item.name || 'Unknown',
          count: Number(item.count ?? item.total ?? item.value ?? 0),
        }));

        setDashboard({
          overview,
          revenueData,
          bookingStatusData,
          recentBookings: bookings,
          users,
          venues,
          refunds,
          tickets,
        });

        if (!overview && !revenue.length && !bookings.length) {
          setError('Dashboard APIs did not return data.');
        }
      } catch (err: any) {
        setError(err.message || 'Unable to load dashboard.');
      } finally {
        setLoading(false);
      }
    };

    loadData();
  }, []);

  const totals = dashboard.overview?.totals ?? {};
  const totalRevenue = moneyFromPaise(totals.revenuePaise);
  const totalRefunds = dashboard.refunds.reduce((sum, refund) => (
    sum + moneyFromPaise(refund.amountPaise ?? refund.refundPaise ?? refund.totalPaise)
  ), 0);
  const activeUsers = dashboard.users.filter(user => user.status === 'ACTIVE').length;
  const activitiesCount = totals.activities
    ?? dashboard.venues.reduce((sum, venue) => sum + Number(venue._count?.activities ?? venue.activitiesCount ?? 0), 0);
  const openTickets = dashboard.tickets.filter(ticket => ticket.status === 'OPEN').length;
  const currentAdmin = useMemo(() => getTokenEmail(), []);

  const cards = [
    { label: 'Revenue', value: formatMoney(totalRevenue), icon: WalletCards, color: 'teal' },
    { label: 'Users', value: totals.users ?? dashboard.users.length, icon: Users, color: 'blue' },
    { label: 'Bookings', value: totals.bookings ?? 0, icon: CalendarDays, color: 'purple' },
    { label: 'Venues', value: totals.venues ?? dashboard.venues.length, icon: Building2, color: 'orange' },
    { label: 'Open Tickets', value: openTickets, icon: Headphones, color: 'red' },
    { label: 'Active Users', value: activeUsers, icon: UserCheck, color: 'sky' },
    { label: 'Activities', value: activitiesCount, icon: Activity, color: 'teal' },
    { label: 'Refunds', value: formatMoney(totalRefunds), icon: IndianRupee, color: 'orange' },
    { label: 'Current Admin', value: currentAdmin, icon: ShieldCheck, color: 'indigo', wide: true },
  ];

  if (loading) return <div className="loading-state">Loading dashboard...</div>;

  return (
    <div className="dashboard-page">
      <div className="page-header">
        <div>
          <h1 className="page-title">Dashboard</h1>
          <p>Business overview</p>
        </div>
        <button className="btn btn-primary" onClick={() => AdminApi.downloadCsv('/admin/dashboard/revenue/csv', 'revenue.csv')}>
          Export CSV
        </button>
      </div>

      {error && <div className="dashboard-error">{error}</div>}

      <div className="dashboard-stat-grid">
        {cards.map(card => {
          const Icon = card.icon;
          return (
            <div key={card.label} className={`glass-card dashboard-stat-card ${card.wide ? 'admin-card' : ''}`}>
              <Icon className={`metric-icon metric-${card.color}`} size={24} />
              <div className="dashboard-stat-value">{card.value}</div>
              <div className="dashboard-stat-label">{card.label}</div>
            </div>
          );
        })}
      </div>

      <div className="dashboard-chart-grid">
        <section className="glass-card dashboard-panel revenue-panel">
          <h2>Revenue (last 30 days)</h2>
          {dashboard.revenueData.length === 0 || dashboard.revenueData.every(item => item.revenue === 0) ? (
            <div className="empty-state">No captured payments yet</div>
          ) : (
            <ResponsiveContainer width="100%" height={220}>
              <AreaChart data={dashboard.revenueData} margin={{ top: 8, right: 20, left: 0, bottom: 0 }}>
                <defs>
                  <linearGradient id="dashboardRevenue" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="var(--primary)" stopOpacity={0.35} />
                    <stop offset="95%" stopColor="var(--primary)" stopOpacity={0.02} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e6edf5" />
                <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: 'var(--text-muted)' }} />
                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: 'var(--text-muted)' }} tickFormatter={value => `₹${value}`} />
                <Tooltip formatter={(value) => [formatMoney(Number(value ?? 0)), 'Revenue']} />
                <Area type="monotone" dataKey="revenue" stroke="var(--primary)" strokeWidth={3} fill="url(#dashboardRevenue)" />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </section>

        <section className="glass-card dashboard-panel status-panel">
          <h2>Bookings by status (30d)</h2>
          {dashboard.bookingStatusData.length === 0 || dashboard.bookingStatusData.every(item => item.count === 0) ? (
            <div className="empty-state compact">No bookings yet</div>
          ) : (
            <ResponsiveContainer width="100%" height={190}>
              <BarChart data={dashboard.bookingStatusData} margin={{ top: 12, right: 12, left: 0, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e6edf5" />
                <XAxis dataKey="status" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: 'var(--text-muted)' }} />
                <YAxis allowDecimals={false} axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: 'var(--text-muted)' }} />
                <Tooltip />
                <Bar dataKey="count" fill="var(--primary)" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </section>
      </div>

      <section className="glass-card dashboard-panel">
        <div className="panel-title-row">
          <h2>Recent bookings</h2>
          <ReceiptIndianRupee size={20} />
        </div>
        {dashboard.recentBookings.length === 0 ? (
          <div className="empty-state compact">No recent bookings yet</div>
        ) : (
          <div className="table-wrapper">
            <table>
              <thead>
                <tr>
                  <th>Booking</th>
                  <th>User</th>
                  <th>Venue</th>
                  <th>Start Time</th>
                  <th>Amount</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {dashboard.recentBookings.map(booking => (
                  <tr key={booking.id}>
                    <td style={{ fontWeight: 800 }}>{booking.publicCode || booking.id}</td>
                    <td>{booking.user?.name || booking.user?.phoneE164 || 'No user'}</td>
                    <td>
                      <div>{booking.slot?.facility?.venue?.name || 'No venue'}</div>
                      <div className="muted-small">{booking.slot?.facility?.name || ''}</div>
                    </td>
                    <td>{booking.slot?.startsAt ? new Date(booking.slot.startsAt).toLocaleString() : 'Not scheduled'}</td>
                    <td>{formatMoney(moneyFromPaise(booking.totalPaise))}</td>
                    <td><span className="badge badge-neutral">{booking.status || 'UNKNOWN'}</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </div>
  );
}

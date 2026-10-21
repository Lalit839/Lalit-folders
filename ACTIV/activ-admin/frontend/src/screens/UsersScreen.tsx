import { useEffect, useState } from 'react';
import { AdminApi } from '../apiClient';

type UserDetails = {
  partial?: boolean;
  errorMessage?: string;
  user: {
    id: string;
    activId?: string;
    name?: string | null;
    phoneE164?: string | null;
    email?: string | null;
    profilePhoto?: string | null;
    role?: string | null;
    isAdmin?: boolean;
    status?: string;
    preferences?: unknown;
    deletionRequestedAt?: string | null;
    createdAt?: string;
    updatedAt?: string;
    partnerRoles?: Array<{
      role: string;
      partner: { id: string; legalName: string; status: string };
    }>;
  };
  stats: {
    totalBookings: number;
    confirmedBookings: number;
    completedBookings: number;
    cancelledBookings: number;
    savedVenues: number;
    reviews: number;
    supportTickets: number;
    notifications: number;
    totalPayments: number;
    successfulPayments: number;
    failedPayments: number;
    pendingPayments: number;
    totalSpentPaise: string;
  };
  recentBookings: Array<{
    id: string;
    publicCode: string;
    status: string;
    totalPaise: string;
    startsAt: string;
    createdAt: string;
    facilityName: string;
    venueName: string;
    cityCode: string;
  }>;
};

const empty = '—';

const formatDate = (value?: string | null) =>
  value ? new Date(value).toLocaleDateString() : empty;

const formatDateTime = (value?: string | null) =>
  value ? new Date(value).toLocaleString() : empty;

const formatRole = (user: any) => {
  if (user.role) return user.role;
  if (user.isAdmin) return 'Admin';
  if (user.partnerRoles?.length || user.partnerUsers?.length) return 'Partner';
  return 'User';
};

const formatMoney = (paise?: string | number | null) => {
  const amount = Number(paise ?? 0) / 100;
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(Number.isFinite(amount) ? amount : 0);
};

const getInitials = (name?: string | null) => {
  const parts = (name || 'User').trim().split(/\s+/).slice(0, 2);
  return parts.map((part) => part[0]?.toUpperCase()).join('') || 'U';
};

const formatActivUserId = (userId?: string | null) =>
  userId ? `ACT-${userId.toUpperCase()}` : empty;

const emptyStats: UserDetails['stats'] = {
  totalBookings: 0,
  confirmedBookings: 0,
  completedBookings: 0,
  cancelledBookings: 0,
  savedVenues: 0,
  reviews: 0,
  supportTickets: 0,
  notifications: 0,
  totalPayments: 0,
  successfulPayments: 0,
  failedPayments: 0,
  pendingPayments: 0,
  totalSpentPaise: '0',
};

const normalizeUserDetails = (payload: any, tableUser: any): UserDetails => {
  const rawUser = payload?.user ?? payload ?? tableUser;
  const rawStats = payload?.stats ?? {};
  const counts = rawUser?._count ?? {};
  const bookings = payload?.recentBookings ?? rawUser?.bookings ?? [];
  const countBookingsByStatus = (status: string) =>
    bookings.filter((booking: any) => booking.status === status).length;
  const totalBookingPaise = bookings.reduce(
    (total: number, booking: any) => total + Number(booking.totalPaise ?? 0),
    0,
  );
  const partnerRoles =
    rawUser?.partnerRoles ??
    rawUser?.partnerUsers?.map((partnerUser: any) => ({
      role: partnerUser.role,
      partner: partnerUser.partner,
    })) ??
    [];

  return {
    user: {
      id: rawUser?.id ?? tableUser.id,
      activId: rawUser?.activId ?? tableUser.activId ?? formatActivUserId(rawUser?.id ?? tableUser.id),
      name: rawUser?.name ?? tableUser.name,
      phoneE164: rawUser?.phoneE164 ?? tableUser.phoneE164,
      email: rawUser?.email ?? tableUser.email,
      profilePhoto: rawUser?.profilePhoto,
      role: rawUser?.role ?? formatRole({ ...tableUser, ...rawUser, partnerRoles }),
      isAdmin: rawUser?.isAdmin ?? tableUser.isAdmin,
      status: rawUser?.status ?? tableUser.status,
      preferences: rawUser?.preferences,
      deletionRequestedAt: rawUser?.deletionRequestedAt,
      createdAt: rawUser?.createdAt ?? tableUser.createdAt,
      updatedAt: rawUser?.updatedAt,
      partnerRoles,
    },
    stats: {
      ...emptyStats,
      totalBookings: rawStats.totalBookings ?? counts.bookings ?? 0,
      confirmedBookings: rawStats.confirmedBookings ?? countBookingsByStatus('CONFIRMED'),
      completedBookings: rawStats.completedBookings ?? countBookingsByStatus('COMPLETED'),
      cancelledBookings: rawStats.cancelledBookings ?? countBookingsByStatus('CANCELLED'),
      savedVenues: rawStats.savedVenues ?? counts.savedVenues ?? 0,
      reviews: rawStats.reviews ?? counts.reviews ?? 0,
      supportTickets: rawStats.supportTickets ?? counts.supportTickets ?? 0,
      notifications: rawStats.notifications ?? counts.notifications ?? 0,
      totalPayments: rawStats.totalPayments ?? 0,
      successfulPayments: rawStats.successfulPayments ?? 0,
      failedPayments: rawStats.failedPayments ?? 0,
      pendingPayments: rawStats.pendingPayments ?? 0,
      totalSpentPaise: rawStats.totalSpentPaise ?? String(totalBookingPaise),
    },
    recentBookings: bookings.map((booking: any) => ({
      id: booking.id,
      publicCode: booking.publicCode ?? booking.id,
      status: booking.status ?? empty,
      totalPaise: booking.totalPaise ?? '0',
      startsAt: booking.startsAt,
      createdAt: booking.createdAt,
      facilityName: booking.facilityName ?? booking.slot?.facility?.name ?? empty,
      venueName: booking.venueName ?? booking.slot?.facility?.venue?.name ?? empty,
      cityCode: booking.cityCode ?? booking.slot?.facility?.venue?.cityCode ?? empty,
    })),
  };
};

const normalizeFallbackUserDetails = (tableUser: any, error: unknown): UserDetails => ({
  ...normalizeUserDetails(null, tableUser),
  partial: true,
  errorMessage: error instanceof Error ? error.message : 'Request failed',
});

export default function UsersScreen() {
  const [users, setUsers] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [appliedSearch, setAppliedSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState<any | null>(null);
  const [detailsCache, setDetailsCache] = useState<Record<string, UserDetails>>({});
  const [detailsLoading, setDetailsLoading] = useState(false);
  const [detailsError, setDetailsError] = useState<string | null>(null);

  useEffect(() => {
    loadUsers();
  }, [page, appliedSearch]);

  useEffect(() => {
    if (!selectedUser) return;

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setSelectedUser(null);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [selectedUser]);

  const loadUsers = async () => {
    try {
      setLoading(true);
      const res = await AdminApi.getUsers({
        page,
        limit: 15,
        ...(appliedSearch ? { search: appliedSearch } : {}),
      });
      setUsers(res.items);
      setTotal(res.total);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const openUserDetails = async (user: any, force = false) => {
    setSelectedUser(user);
    if (!force && detailsCache[user.id]) {
      setDetailsError(null);
      setDetailsLoading(false);
      return;
    }

    try {
      setDetailsLoading(true);
      setDetailsError(null);
      const details = await AdminApi.getUserDetails(user.id);
      setDetailsCache((cache) => ({ ...cache, [user.id]: normalizeUserDetails(details, user) }));
    } catch (e) {
      setDetailsCache((cache) => ({
        ...cache,
        [user.id]: normalizeFallbackUserDetails(user, e),
      }));
      setDetailsError(null);
    } finally {
      setDetailsLoading(false);
    }
  };

  const details = selectedUser ? detailsCache[selectedUser.id] : null;

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Users</h1>
          <p style={{ color: 'var(--text-muted)' }}>{total} total users</p>
        </div>
        <button className="btn btn-primary" onClick={() => AdminApi.downloadCsv('/admin/users/csv', 'users.csv')}>
          Export CSV
        </button>
      </div>

      <form
        className="users-toolbar"
        onSubmit={(event) => {
          event.preventDefault();
          setPage(1);
          setAppliedSearch(search.trim());
        }}
      >
        <input
          className="input-control"
          placeholder="Search name, phone, email, UUID, or ACT ID"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
        <button className="btn" type="submit">Search</button>
        {appliedSearch && (
          <button
            className="btn"
            type="button"
            onClick={() => {
              setSearch('');
              setAppliedSearch('');
              setPage(1);
            }}
          >
            Clear
          </button>
        )}
      </form>

      <div className="glass-card table-wrapper">
        {loading ? (
          <div style={{ padding: '40px', textAlign: 'center' }}>Loading...</div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Phone</th>
                <th>Email</th>
                <th>Role</th>
                <th>Status</th>
                <th>Joined</th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => (
                <tr
                  className="clickable-row"
                  key={u.id}
                  onClick={(event) => {
                    if ((event.target as HTMLElement).closest('button,a,input,select,textarea')) return;
                    openUserDetails(u);
                  }}
                  tabIndex={0}
                  onKeyDown={(event) => {
                    if (event.key === 'Enter' || event.key === ' ') {
                      event.preventDefault();
                      openUserDetails(u);
                    }
                  }}
                >
                  <td style={{ fontWeight: 500 }}>{u.name || empty}</td>
                  <td>{u.phoneE164 || empty}</td>
                  <td>{u.email || empty}</td>
                  <td>
                    <span className="role-pill">{formatRole(u)}</span>
                  </td>
                  <td>
                    <span className="badge" style={{ background: u.status === 'ACTIVE' ? 'var(--success)' : 'var(--text-muted)', color: '#050603' }}>
                      {u.status}
                    </span>
                  </td>
                  <td>{formatDate(u.createdAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '20px', gap: '10px' }}>
        <button className="btn" disabled={page === 1} onClick={() => setPage((p) => p - 1)}>Previous</button>
        <button className="btn" disabled={users.length < 15} onClick={() => setPage((p) => p + 1)}>Next</button>
      </div>

      {selectedUser && (
        <div className="user-modal-backdrop" onMouseDown={() => setSelectedUser(null)}>
          <aside className="user-detail-modal glass-card" onMouseDown={(event) => event.stopPropagation()} role="dialog" aria-modal="true">
            <button className="user-modal-close" type="button" onClick={() => setSelectedUser(null)} aria-label="Close user details">
              x
            </button>

            {detailsLoading && !details ? (
              <UserDetailsSkeleton />
            ) : detailsError ? (
              <div className="user-detail-error">
                <h2>Could not load user details</h2>
                <p>{detailsError}</p>
                <button className="btn btn-primary" type="button" onClick={() => openUserDetails(selectedUser, true)}>
                  Retry
                </button>
              </div>
            ) : details ? (
              <UserDetailsPanel details={details} />
            ) : (
              <UserDetailsSkeleton />
            )}
          </aside>
        </div>
      )}
    </div>
  );
}

function UserDetailsPanel({ details }: { details: UserDetails }) {
  const user = details.user;
  const preferences =
    user.preferences && typeof user.preferences === 'object'
      ? Object.entries(user.preferences as Record<string, unknown>)
      : [];

  return (
    <div>
      <header className="user-detail-header">
        {user.profilePhoto ? (
          <img className="user-detail-avatar" src={user.profilePhoto} alt="" />
        ) : (
          <div className="user-detail-avatar">{getInitials(user.name)}</div>
        )}
        <div>
          <h2>{user.name || empty}</h2>
          <p>{user.phoneE164 || empty} / {user.email || empty}</p>
          <div className="user-detail-chip-row">
            <span className="badge" style={{ background: user.status === 'ACTIVE' ? 'var(--success)' : 'var(--text-muted)', color: '#050603' }}>
              {user.status || empty}
            </span>
            <span className="role-pill">{user.role || 'User'}</span>
          </div>
        </div>
      </header>

      <div className="user-summary-grid">
        <SummaryCard label="Total Bookings" value={details.stats.totalBookings} />
        <SummaryCard label="Completed" value={details.stats.completedBookings} />
        <SummaryCard label="Cancelled" value={details.stats.cancelledBookings} />
        <SummaryCard label="Total Spent" value={formatMoney(details.stats.totalSpentPaise)} />
      </div>

      {details.partial && (
        <div className="user-detail-notice">
          Full details could not load from the API. Showing table data only. {details.errorMessage}
        </div>
      )}

      <section className="user-detail-section">
        <h3>Personal Details</h3>
        <DetailGrid
          items={[
            ['Full name', user.name],
            ['Phone number', user.phoneE164],
            ['Email', user.email],
            ['ACTIV ID', user.activId ?? formatActivUserId(user.id)],
            ['Profile image', user.profilePhoto],
          ]}
        />
      </section>

      <section className="user-detail-section">
        <h3>Account Details</h3>
        <DetailGrid
          items={[
            ['Role', user.role || 'User'],
            ['Account status', user.status],
            ['Admin status', user.isAdmin ? 'Yes' : 'No'],
            ['Joined / created', formatDateTime(user.createdAt)],
            ['Updated', formatDateTime(user.updatedAt)],
            ['Deletion requested', formatDateTime(user.deletionRequestedAt)],
            ['Email verified', empty],
            ['Phone verified', empty],
            ['Last login', empty],
          ]}
        />
      </section>

      {user.partnerRoles && user.partnerRoles.length > 0 && (
        <section className="user-detail-section">
          <h3>Partner Access</h3>
          <div className="compact-list">
            {user.partnerRoles.map((partnerRole) => (
              <div className="compact-list-item" key={`${partnerRole.partner.id}-${partnerRole.role}`}>
                <strong>{partnerRole.partner.legalName}</strong>
                <span>{partnerRole.role} / {partnerRole.partner.status}</span>
              </div>
            ))}
          </div>
        </section>
      )}

      <section className="user-detail-section">
        <h3>Booking Activity</h3>
        <DetailGrid
          items={[
            ['Total bookings', details.stats.totalBookings],
            ['Confirmed bookings', details.stats.confirmedBookings],
            ['Completed bookings', details.stats.completedBookings],
            ['Cancelled bookings', details.stats.cancelledBookings],
          ]}
        />
      </section>

      <section className="user-detail-section">
        <h3>Payment Information</h3>
        <DetailGrid
          items={[
            ['Payment/order count', details.stats.totalPayments],
            ['Successful payments', details.stats.successfulPayments],
            ['Failed payments', details.stats.failedPayments],
            ['Pending payments', details.stats.pendingPayments],
            ['Total amount spent', formatMoney(details.stats.totalSpentPaise)],
          ]}
        />
      </section>

      <section className="user-detail-section">
        <h3>Engagement</h3>
        <DetailGrid
          items={[
            ['Saved venues', details.stats.savedVenues],
            ['Reviews', details.stats.reviews],
            ['Support tickets', details.stats.supportTickets],
            ['Notifications', details.stats.notifications],
          ]}
        />
      </section>

      <section className="user-detail-section">
        <h3>Profile Preferences</h3>
        {preferences.length > 0 ? (
          <DetailGrid items={preferences.map(([key, value]) => [key, typeof value === 'string' ? value : JSON.stringify(value)])} />
        ) : (
          <p className="detail-empty">{empty}</p>
        )}
      </section>

      <section className="user-detail-section">
        <h3>Recent Bookings</h3>
        {details.recentBookings.length > 0 ? (
          <div className="recent-booking-list">
            {details.recentBookings.map((booking) => (
              <div className="recent-booking-item" key={booking.id}>
                <div>
                  <strong>{booking.publicCode}</strong>
                  <span>{booking.venueName} / {booking.facilityName}</span>
                </div>
                <div>
                  <span className="role-pill">{booking.status}</span>
                  <span>{formatMoney(booking.totalPaise)}</span>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <p className="detail-empty">{empty}</p>
        )}
      </section>
    </div>
  );
}

function SummaryCard({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="user-summary-card">
      <span>{value}</span>
      <p>{label}</p>
    </div>
  );
}

function DetailGrid({ items }: { items: Array<[string, unknown]> }) {
  return (
    <div className="detail-grid">
      {items.map(([label, value]) => (
        <div className="detail-field" key={label}>
          <span>{label}</span>
          <strong>{value === null || value === undefined || value === '' ? empty : String(value)}</strong>
        </div>
      ))}
    </div>
  );
}

function UserDetailsSkeleton() {
  return (
    <div className="user-detail-skeleton">
      <div className="skeleton-row header" />
      <div className="user-summary-grid">
        {[0, 1, 2, 3].map((item) => <div className="skeleton-card" key={item} />)}
      </div>
      {[0, 1, 2].map((item) => <div className="skeleton-block" key={item} />)}
    </div>
  );
}

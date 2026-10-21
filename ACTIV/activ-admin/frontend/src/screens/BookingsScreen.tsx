import { type FormEvent, useEffect, useState } from 'react';
import { AdminApi } from '../apiClient';

const empty = '-';

const formatDateTime = (value?: string | null) =>
  value ? new Date(value).toLocaleString() : empty;

const formatMoney = (paise?: string | number | null) => {
  const amount = Number(paise ?? 0) / 100;
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(Number.isFinite(amount) ? amount : 0);
};

const getStatusColor = (status?: string) => {
  switch (status) {
    case 'CONFIRMED':
    case 'COMPLETED':
      return 'var(--success)';
    case 'CANCELLED':
      return 'var(--danger)';
    default:
      return 'var(--warning)';
  }
};

const minutesBetween = (start?: string, end?: string) => {
  if (!start || !end) return empty;
  const minutes = Math.round((new Date(end).getTime() - new Date(start).getTime()) / 60000);
  return Number.isFinite(minutes) ? `${minutes} min` : empty;
};

const parseRupeesToPaise = (value: string) => {
  const trimmed = value.trim();
  if (!/^\d+(\.\d{1,2})?$/.test(trimmed)) return null;
  const [rupees, paise = ''] = trimmed.split('.');
  return Number(rupees) * 100 + Number(paise.padEnd(2, '0'));
};

const refundStatusOptions = [
  { value: 'PENDING', label: 'Initiated / In process' },
  { value: 'PROCESSED', label: 'Approved / Credited' },
  { value: 'EXCEPTION_REVIEW', label: 'Needs review' },
  { value: 'FAILED', label: 'Failed' },
];

export default function BookingsScreen() {
  const [bookings, setBookings] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [selectedBooking, setSelectedBooking] = useState<any | null>(null);
  const [detailsCache, setDetailsCache] = useState<Record<string, any>>({});
  const [detailsLoading, setDetailsLoading] = useState(false);
  const [detailsError, setDetailsError] = useState<string | null>(null);

  useEffect(() => {
    loadBookings();
  }, [page]);

  useEffect(() => {
    if (!selectedBooking) return;

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setSelectedBooking(null);
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [selectedBooking]);

  const loadBookings = async () => {
    try {
      setLoading(true);
      const res = await AdminApi.getBookings({ page, limit: 15 });
      setBookings(res.items);
      setTotal(res.total);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const openBookingDetails = async (booking: any, force = false) => {
    setSelectedBooking(booking);
    if (!force && detailsCache[booking.id]) {
      setDetailsError(null);
      setDetailsLoading(false);
      return;
    }

    try {
      setDetailsLoading(true);
      setDetailsError(null);
      const details = await AdminApi.getBookingDetails(booking.id);
      setDetailsCache((cache) => ({ ...cache, [booking.id]: details }));
    } catch (e) {
      setDetailsError(e instanceof Error ? e.message : 'Failed to load booking details');
    } finally {
      setDetailsLoading(false);
    }
  };

  const details = selectedBooking ? detailsCache[selectedBooking.id] : null;

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Bookings</h1>
          <p style={{ color: 'var(--text-muted)' }}>{total} total bookings</p>
        </div>
        <button className="btn btn-primary" onClick={() => AdminApi.downloadCsv('/admin/bookings/csv', 'bookings.csv')}>
          Export CSV
        </button>
      </div>

      <div className="glass-card table-wrapper">
        {loading ? (
          <div style={{ padding: '40px', textAlign: 'center' }}>Loading...</div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Booking ID</th>
                <th>User</th>
                <th>Venue & Facility</th>
                <th>Start Time</th>
                <th>Amount</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {bookings.map((booking) => (
                <tr
                  className="clickable-row"
                  key={booking.id}
                  onClick={(event) => {
                    if ((event.target as HTMLElement).closest('button,a,input,select,textarea')) return;
                    openBookingDetails(booking);
                  }}
                  tabIndex={0}
                  onKeyDown={(event) => {
                    if (event.key === 'Enter' || event.key === ' ') {
                      event.preventDefault();
                      openBookingDetails(booking);
                    }
                  }}
                >
                  <td style={{ fontWeight: 500 }}>{booking.publicCode}</td>
                  <td>
                    <div>{booking.user?.name || 'No Name'}</div>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>{booking.user?.phoneE164 || empty}</div>
                  </td>
                  <td>
                    <div>{booking.slot?.facility?.venue?.name || empty}</div>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>{booking.slot?.facility?.name || empty}</div>
                  </td>
                  <td>{formatDateTime(booking.slot?.startsAt ?? booking.startsAt)}</td>
                  <td>{formatMoney(booking.totalPaise)}</td>
                  <td>
                    <span className="badge" style={{ background: getStatusColor(booking.status), color: '#050603' }}>
                      {booking.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '20px', gap: '10px' }}>
        <button className="btn" disabled={page === 1} onClick={() => setPage((p) => p - 1)}>Previous</button>
        <button className="btn" disabled={bookings.length < 15} onClick={() => setPage((p) => p + 1)}>Next</button>
      </div>

      {selectedBooking && (
        <div className="user-modal-backdrop" onMouseDown={() => setSelectedBooking(null)}>
          <aside className="user-detail-modal booking-detail-modal glass-card" onMouseDown={(event) => event.stopPropagation()} role="dialog" aria-modal="true">
            <button className="user-modal-close" type="button" onClick={() => setSelectedBooking(null)} aria-label="Close booking details">
              x
            </button>

            {detailsLoading && !details ? (
              <BookingDetailsSkeleton />
            ) : detailsError ? (
              <div className="user-detail-error">
                <h2>Could not load booking details</h2>
                <p>{detailsError}</p>
                <button className="btn btn-primary" type="button" onClick={() => openBookingDetails(selectedBooking, true)}>
                  Retry
                </button>
              </div>
            ) : details ? (
              <BookingDetailsPanel
                booking={details}
                onRefundInitiated={() => openBookingDetails(selectedBooking, true)}
              />
            ) : (
              <BookingDetailsSkeleton />
            )}
          </aside>
        </div>
      )}
    </div>
  );
}

function BookingDetailsPanel({
  booking,
  onRefundInitiated,
}: {
  booking: any;
  onRefundInitiated: () => Promise<void>;
}) {
  const [refundAmount, setRefundAmount] = useState('');
  const [refundStatus, setRefundStatus] = useState('PENDING');
  const [refundProviderRef, setRefundProviderRef] = useState('');
  const [refundReason, setRefundReason] = useState('');
  const [selectedRefundId, setSelectedRefundId] = useState('new');
  const [refundSubmitting, setRefundSubmitting] = useState(false);
  const [refundMessage, setRefundMessage] = useState<string | null>(null);
  const slot = booking.slot;
  const facility = slot?.facility;
  const venue = facility?.venue;
  const profile = venue?.partnerProfile;
  const payment = booking.payments?.[0];
  const coupon = booking.attempt?.coupon;
  const totalRefunded = (booking.refunds || []).reduce(
    (total: number, refund: any) => total + Number(refund.amountPaise ?? 0),
    0,
  );
  const trackedRefunds = (booking.refunds || []).filter((refund: any) => refund.status !== 'FAILED');
  const totalTrackedRefunds = trackedRefunds.reduce(
    (total: number, refund: any) => total + Number(refund.amountPaise ?? 0),
    0,
  );
  const managedPayment =
    (booking.payments || []).find((item: any) =>
      ['CAPTURED', 'REFUND_PENDING', 'REFUNDED'].includes(item.status),
    ) ?? booking.payments?.[0];
  const selectedRefund = (booking.refunds || []).find((refund: any) => refund.id === selectedRefundId);
  const trackedRefundsExcludingSelected = trackedRefunds.filter(
    (refund: any) => refund.id !== selectedRefundId,
  );
  const trackedRefundsExcludingSelectedTotal = trackedRefundsExcludingSelected.reduce(
    (total: number, refund: any) => total + Number(refund.amountPaise ?? 0),
    0,
  );
  const refundableAmount = Math.max(
    0,
    Number(managedPayment?.amountPaise ?? 0) - totalTrackedRefunds,
  );
  const editableRefundLimit = Math.max(
    0,
    Number(managedPayment?.amountPaise ?? 0) - trackedRefundsExcludingSelectedTotal,
  );
  const cancelEvent = (booking.events || [])
    .slice()
    .reverse()
    .find((event: any) => event.toStatus === 'CANCELLED');
  const canManageRefund = booking.status === 'CANCELLED' && Boolean(managedPayment);

  useEffect(() => {
    setSelectedRefundId('new');
    setRefundAmount('');
    setRefundStatus('PENDING');
    setRefundProviderRef('');
    setRefundReason('');
    setRefundMessage(null);
  }, [booking.id]);

  const handleRefundSelection = (value: string) => {
    setSelectedRefundId(value);
    setRefundMessage(null);
    if (value === 'new') {
      setRefundAmount('');
      setRefundStatus('PENDING');
      setRefundProviderRef('');
      return;
    }
    const refund = (booking.refunds || []).find((item: any) => item.id === value);
    setRefundAmount(refund ? String(Number(refund.amountPaise ?? 0) / 100) : '');
    setRefundStatus(refund?.status ?? 'PENDING');
    setRefundProviderRef(refund?.providerRef ?? '');
  };

  const submitRefund = async (event: FormEvent) => {
    event.preventDefault();
    const amountPaise = parseRupeesToPaise(refundAmount);
    if (!amountPaise || amountPaise <= 0) {
      setRefundMessage('Enter a valid refund amount.');
      return;
    }
    if (amountPaise > editableRefundLimit) {
      setRefundMessage('Refund amount exceeds remaining refundable balance.');
      return;
    }

    try {
      setRefundSubmitting(true);
      setRefundMessage(null);
      if (selectedRefund) {
        await AdminApi.updateBookingRefund(booking.id, selectedRefund.id, {
          amountPaise,
          status: refundStatus,
          providerRef: refundProviderRef.trim() || undefined,
          reason: refundReason.trim() || undefined,
        });
        setRefundMessage('Refund updated.');
      } else {
        await AdminApi.initiateBookingRefund(booking.id, {
          amountPaise,
          paymentId: managedPayment.id,
          status: refundStatus,
          providerRef: refundProviderRef.trim() || undefined,
          reason: refundReason.trim() || undefined,
        });
        setRefundAmount('');
        setRefundReason('');
        setRefundProviderRef('');
        setRefundStatus('PENDING');
        setSelectedRefundId('new');
        setRefundMessage('Refund saved. Pending refunds will be processed by the refund worker.');
      }
      await onRefundInitiated();
    } catch (error) {
      setRefundMessage(error instanceof Error ? error.message : 'Failed to save refund');
    } finally {
      setRefundSubmitting(false);
    }
  };

  return (
    <div>
      <header className="booking-detail-header">
        <div>
          <h2>{booking.publicCode || booking.id}</h2>
          <p>Created {formatDateTime(booking.createdAt)}</p>
        </div>
        <span className="badge" style={{ background: getStatusColor(booking.status), color: '#050603' }}>
          {booking.status}
        </span>
      </header>

      <div className="user-summary-grid">
        <SummaryCard label="Total Amount" value={formatMoney(booking.totalPaise)} />
        <SummaryCard label="Payment Status" value={payment?.status || empty} />
        <SummaryCard label="Duration" value={minutesBetween(slot?.startsAt, slot?.endsAt)} />
        <SummaryCard label="Status" value={booking.status || empty} />
      </div>

      <section className="user-detail-section">
        <h3>Booking Information</h3>
        <DetailGrid
          items={[
            ['Internal booking UUID', booking.id],
            ['Booking ID', booking.publicCode],
            ['Booking status', booking.status],
            ['Policy version', booking.policyVersion],
            ['Booking attempt ID', booking.attempt?.id],
            ['Attempt status', booking.attempt?.status],
            ['Quantity / guests', booking.attempt?.quantity],
            ['Reschedule count', booking.rescheduleCount],
            ['Created at', formatDateTime(booking.createdAt)],
            ['Updated at', formatDateTime(booking.updatedAt)],
          ]}
        />
      </section>

      <section className="user-detail-section">
        <h3>Customer Information</h3>
        <DetailGrid
          items={[
            ['User ID', booking.user?.id],
            ['Full name', booking.user?.name],
            ['Phone', booking.user?.phoneE164],
            ['Email', booking.user?.email],
            ['Account status', booking.user?.status],
            ['Joined date', formatDateTime(booking.user?.createdAt)],
          ]}
        />
      </section>

      <section className="user-detail-section">
        <h3>Venue / Facility Information</h3>
        <DetailGrid
          items={[
            ['Venue ID', venue?.id],
            ['Venue name', profile?.displayName || venue?.name],
            ['Venue status', venue?.status],
            ['Address line 1', profile?.addressLine1],
            ['Address line 2', profile?.addressLine2],
            ['City', profile?.city || venue?.cityCode],
            ['State', profile?.state],
            ['Pincode', profile?.postalCode],
            ['Facility ID', facility?.id],
            ['Facility name', facility?.name],
            ['Facility capacity', facility?.capacity],
            ['Activity / sport', facility?.activity?.name],
            ['Activity type', facility?.activity?.type],
            ['Sport code', facility?.activity?.sportCode],
            ['Slot ID', slot?.id],
          ]}
        />
      </section>

      <section className="user-detail-section">
        <h3>Slot / Timing Information</h3>
        <DetailGrid
          items={[
            ['Booking date', formatDateTime(booking.startsAt)],
            ['Start date/time', formatDateTime(booking.startsAt)],
            ['Slot start', formatDateTime(slot?.startsAt)],
            ['Slot end', formatDateTime(slot?.endsAt)],
            ['Duration', minutesBetween(slot?.startsAt, slot?.endsAt)],
            ['Slot status', slot?.status],
            ['Slot capacity', slot?.capacity],
            ['Booked quantity', slot?.bookedQuantity],
            ['Completed/cancelled at', formatDateTime(cancelEvent?.createdAt)],
            ['Timezone', empty],
          ]}
        />
      </section>

      <section className="user-detail-section">
        <h3>Payment Information</h3>
        {(booking.payments || []).length > 0 ? (
          <div className="compact-list">
            {booking.payments.map((item: any) => (
              <div className="compact-list-item" key={item.id}>
                <div>
                  <strong>{item.provider} / {item.status}</strong>
                  <span>{item.id}</span>
                </div>
                <div>
                  <span>{formatMoney(item.amountPaise)}</span>
                  <span>Created {formatDateTime(item.createdAt)}</span>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <p className="detail-empty">{empty}</p>
        )}
        <DetailGrid
          items={[
            ['Payment ID', payment?.id],
            ['Provider', payment?.provider],
            ['Provider order ID', payment?.providerOrderId],
            ['Provider payment ID', payment?.providerPaymentId],
            ['Provider event ID', payment?.providerEventId],
            ['Payment status', payment?.status],
            ['Payment method/source', empty],
            ['Payment amount', formatMoney(payment?.amountPaise)],
            ['Payment created', formatDateTime(payment?.createdAt)],
            ['Payment updated', formatDateTime(payment?.updatedAt)],
          ]}
        />
      </section>

      <section className="user-detail-section">
        <h3>Pricing Breakdown</h3>
        <DetailGrid
          items={[
            ['Base price', formatMoney(booking.subtotalPaise)],
            ['Discount', `-${formatMoney(booking.discountPaise)}`],
            ['Slot price', formatMoney(slot?.pricePaise)],
            ['Total', formatMoney(booking.totalPaise)],
            ['Paid', formatMoney(payment?.amountPaise)],
            ['Refunded', formatMoney(totalRefunded)],
            ['Coupon code', coupon?.code],
            ['Coupon ID', coupon?.id],
            ['Coupon percent off', coupon?.percentOff],
            ['Coupon amount off', coupon?.amountOffPaise ? formatMoney(coupon.amountOffPaise) : empty],
          ]}
        />
      </section>

      <section className="user-detail-section">
        <h3>Refund / Cancellation Information</h3>
        <DetailGrid
          items={[
            ['Cancellation reason', cancelEvent?.metadata?.reason],
            ['Cancelled by ID', cancelEvent?.actorId],
            ['Cancelled at', formatDateTime(cancelEvent?.createdAt)],
            ['Refund amount', formatMoney(totalRefunded)],
            ['Refund tracked', formatMoney(totalTrackedRefunds)],
            ['Refundable remaining', formatMoney(refundableAmount)],
            ['Refund count', booking.refunds?.length ?? 0],
            ['Refund eligibility', empty],
          ]}
        />
        {booking.status === 'CANCELLED' && (
          <div className="refund-manager section-offset">
            <div>
              <h4>Manage Refund</h4>
              <p>
                Payment amount: {formatMoney(managedPayment?.amountPaise)} / Remaining: {formatMoney(refundableAmount)}
              </p>
            </div>
            {canManageRefund ? (
              <form className="refund-form" onSubmit={submitRefund}>
                <select
                  className="input-control"
                  value={selectedRefundId}
                  onChange={(event) => handleRefundSelection(event.target.value)}
                >
                  <option value="new">New refund</option>
                  {(booking.refunds || []).map((refund: any) => (
                    <option key={refund.id} value={refund.id}>
                      {refund.status} / {formatMoney(refund.amountPaise)}
                    </option>
                  ))}
                </select>
                <input
                  className="input-control"
                  inputMode="decimal"
                  placeholder="Refund amount in INR"
                  value={refundAmount}
                  onChange={(event) => setRefundAmount(event.target.value)}
                />
                <select
                  className="input-control"
                  value={refundStatus}
                  onChange={(event) => setRefundStatus(event.target.value)}
                >
                  {refundStatusOptions.map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
                <input
                  className="input-control"
                  placeholder="Gateway / bank reference"
                  value={refundProviderRef}
                  onChange={(event) => setRefundProviderRef(event.target.value)}
                />
                <input
                  className="input-control"
                  placeholder="Reason (optional)"
                  value={refundReason}
                  onChange={(event) => setRefundReason(event.target.value)}
                />
                <button className="btn btn-primary" disabled={refundSubmitting} type="submit">
                  {refundSubmitting ? 'Saving...' : selectedRefund ? 'Update Refund' : 'Save Refund'}
                </button>
              </form>
            ) : (
              <p className="detail-empty">
                No payment record is available for this booking.
              </p>
            )}
            {refundMessage && <p className="refund-message">{refundMessage}</p>}
          </div>
        )}
        {(booking.refunds || []).length > 0 && (
          <div className="compact-list section-offset">
            {booking.refunds.map((refund: any) => (
              <div className="compact-list-item" key={refund.id}>
                <div>
                  <strong>{refund.status}</strong>
                  <span>{refund.id}</span>
                  <span>Reference: {refund.providerRef || empty}</span>
                </div>
                <div>
                  <span>{formatMoney(refund.amountPaise)}</span>
                  <span>{formatDateTime(refund.createdAt)}</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>

      <section className="user-detail-section">
        <h3>Request / Device Information</h3>
        <DetailGrid
          items={[
            ['IP address', booking.requestMetadata?.ip],
            ['User agent', booking.requestMetadata?.userAgent],
            ['Device ID', booking.requestMetadata?.deviceId],
            ['Platform', booking.requestMetadata?.platform],
            ['App version', booking.requestMetadata?.appVersion],
            ['Request ID', booking.requestMetadata?.requestId],
            ['Session reference', booking.requestMetadata?.sessionId],
            ['Source app', empty],
          ]}
        />
        <p className="detail-empty section-offset">
          IP/device/request metadata is not currently stored for bookings in this schema.
        </p>
      </section>

      <section className="user-detail-section">
        <h3>Booking Timeline</h3>
        <Timeline booking={booking} />
      </section>
    </div>
  );
}

function Timeline({ booking }: { booking: any }) {
  const items = [
    { id: 'created', label: 'Booking Created', at: booking.createdAt },
    ...(booking.events || []).map((event: any) => ({
      id: event.id,
      label: event.fromStatus ? `${event.fromStatus} to ${event.toStatus}` : event.toStatus,
      at: event.createdAt,
      meta: event.metadata?.reason,
    })),
    ...(booking.auditEvents || []).map((event: any) => ({
      id: event.id,
      label: event.action,
      at: event.createdAt,
      meta: event.actorId ? `Actor ${event.actorId}` : undefined,
    })),
  ].filter((item) => item.at);

  if (items.length === 0) return <p className="detail-empty">{empty}</p>;

  return (
    <div className="timeline-list">
      {items.map((item) => (
        <div className="timeline-item" key={item.id}>
          <span className="timeline-dot" />
          <div>
            <strong>{item.label}</strong>
            <p>{formatDateTime(item.at)}</p>
            {item.meta && <p>{item.meta}</p>}
          </div>
        </div>
      ))}
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

function BookingDetailsSkeleton() {
  return (
    <div className="user-detail-skeleton">
      <div className="skeleton-row header" />
      <div className="user-summary-grid">
        {[0, 1, 2, 3].map((item) => <div className="skeleton-card" key={item} />)}
      </div>
      {[0, 1, 2, 3].map((item) => <div className="skeleton-block" key={item} />)}
    </div>
  );
}

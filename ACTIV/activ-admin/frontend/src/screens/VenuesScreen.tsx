import { type FormEvent, type ReactNode, useCallback, useEffect, useMemo, useState } from 'react';
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

const prettyJson = (value: unknown) => JSON.stringify(value ?? {}, null, 2);

const parseJson = (value: string, label: string) => {
  try {
    const parsed = JSON.parse(value || '{}');
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
      throw new Error();
    }
    return parsed;
  } catch {
    throw new Error(`${label} must be valid JSON object data.`);
  }
};

const getStatusColor = (status?: string) => {
  switch (status) {
    case 'PUBLISHED':
      return 'var(--success)';
    case 'DRAFT':
      return 'var(--warning)';
    case 'ARCHIVED':
      return 'var(--text-muted)';
    default:
      return 'var(--primary)';
  }
};

const imageDisplayUrl = (image: any) =>
  image?.metadata?.optimizedUrl || image?.metadata?.secureUrl || image?.url;

export default function VenuesScreen() {
  const [venues, setVenues] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [selectedVenue, setSelectedVenue] = useState<any | null>(null);
  const [detailsCache, setDetailsCache] = useState<Record<string, any>>({});
  const [detailsLoading, setDetailsLoading] = useState(false);
  const [detailsError, setDetailsError] = useState<string | null>(null);
  const [dirty, setDirty] = useState(false);

  const loadVenues = useCallback(async () => {
    try {
      setLoading(true);
      const res = await AdminApi.getVenues({ page, limit: 15 });
      setVenues(res.items);
      setTotal(res.total);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [page]);

  const closeDetails = useCallback(() => {
    if (dirty && !window.confirm('Discard unsaved venue changes?')) return;
    setDirty(false);
    setSelectedVenue(null);
  }, [dirty]);

  useEffect(() => {
    loadVenues();
  }, [loadVenues]);

  useEffect(() => {
    if (!selectedVenue) return;
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') closeDetails();
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [selectedVenue, closeDetails]);

  const openVenueDetails = async (venue: any, force = false) => {
    setSelectedVenue(venue);
    setDirty(false);
    if (!force && detailsCache[venue.id]) {
      setDetailsError(null);
      setDetailsLoading(false);
      return;
    }

    try {
      setDetailsLoading(true);
      setDetailsError(null);
      const details = await AdminApi.getVenueDetails(venue.id);
      setDetailsCache((cache) => ({ ...cache, [venue.id]: details }));
    } catch (e) {
      setDetailsError(e instanceof Error ? e.message : 'Failed to load venue details');
    } finally {
      setDetailsLoading(false);
    }
  };

  const refreshSelectedVenue = async () => {
    if (!selectedVenue) return;
    const details = await AdminApi.getVenueDetails(selectedVenue.id);
    setDetailsCache((cache) => ({ ...cache, [selectedVenue.id]: details }));
  };

  const handleStatusChange = async (venueId: string, newStatus: string) => {
    try {
      await AdminApi.updateVenueStatus(venueId, newStatus);
      await loadVenues();
      setDetailsCache((cache) => {
        const details = cache[venueId];
        if (!details) return cache;
        return { ...cache, [venueId]: { ...details, venue: { ...details.venue, status: newStatus } } };
      });
    } catch {
      alert('Failed to update status');
    }
  };

  const details = selectedVenue ? detailsCache[selectedVenue.id] : null;

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Venues</h1>
          <p style={{ color: 'var(--text-muted)' }}>{total} total venues</p>
        </div>
      </div>

      <div className="glass-card table-wrapper">
        {loading ? (
          <div style={{ padding: '40px', textAlign: 'center' }}>Loading...</div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Venue Name</th>
                <th>City</th>
                <th>Partner</th>
                <th>Activities Count</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {venues.map((venue) => (
                <tr
                  className="clickable-row"
                  key={venue.id}
                  onClick={(event) => {
                    if ((event.target as HTMLElement).closest('button,a,input,select,textarea')) return;
                    openVenueDetails(venue);
                  }}
                  tabIndex={0}
                  onKeyDown={(event) => {
                    if (event.key === 'Enter' || event.key === ' ') {
                      event.preventDefault();
                      openVenueDetails(venue);
                    }
                  }}
                >
                  <td style={{ fontWeight: 500 }}>{venue.name}</td>
                  <td>{venue.cityCode}</td>
                  <td>{venue.partner?.legalName || empty}</td>
                  <td>{venue._count?.activities ?? 0}</td>
                  <td>
                    <select
                      className="input-control status-select"
                      style={{ padding: '6px 10px', fontSize: '13px', background: getStatusColor(venue.status), color: '#050603', border: 'none' }}
                      value={venue.status}
                      onChange={(event) => handleStatusChange(venue.id, event.target.value)}
                    >
                      <option value="DRAFT">DRAFT</option>
                      <option value="PUBLISHED">PUBLISHED</option>
                      <option value="ARCHIVED">ARCHIVED</option>
                    </select>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <div className="pagination">
        <button className="btn" disabled={page === 1} onClick={() => setPage((p) => p - 1)}>Previous</button>
        <button className="btn" disabled={venues.length < 15} onClick={() => setPage((p) => p + 1)}>Next</button>
      </div>

      {selectedVenue && (
        <div className="user-modal-backdrop" onMouseDown={closeDetails}>
          <aside className="user-detail-modal venue-detail-modal glass-card" onMouseDown={(event) => event.stopPropagation()} role="dialog" aria-modal="true">
            <button className="user-modal-close" type="button" onClick={closeDetails} aria-label="Close venue details">
              x
            </button>
            {detailsLoading && !details ? (
              <VenueDetailsSkeleton />
            ) : detailsError ? (
              <div className="user-detail-error">
                <h2>Could not load venue details</h2>
                <p>{detailsError}</p>
                <button className="btn btn-primary" type="button" onClick={() => openVenueDetails(selectedVenue, true)}>
                  Retry
                </button>
              </div>
            ) : details ? (
              <VenueDetailsPanel
                details={details}
                onDirtyChange={setDirty}
                onReload={refreshSelectedVenue}
                onSaved={async (updated) => {
                  setDirty(false);
                  setDetailsCache((cache) => ({ ...cache, [selectedVenue.id]: updated }));
                  await loadVenues();
                }}
              />
            ) : (
              <VenueDetailsSkeleton />
            )}
          </aside>
        </div>
      )}
    </div>
  );
}

function VenueDetailsPanel({
  details,
  onDirtyChange,
  onReload,
  onSaved,
}: {
  details: any;
  onDirtyChange: (dirty: boolean) => void;
  onReload: () => Promise<void>;
  onSaved: (details: any) => Promise<void>;
}) {
  const { venue, stats } = details;
  const profile = venue.partnerProfile || {};
  const businessProfile = venue.partner?.businessProfile || {};
  const [editMode, setEditMode] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imageUrl, setImageUrl] = useState('');
  const [imageCaption, setImageCaption] = useState('');
  const [imagePrimary, setImagePrimary] = useState(false);
  const [imageBusyId, setImageBusyId] = useState<string | null>(null);
  const [activityId, setActivityId] = useState('');
  const [facilityEdits, setFacilityEdits] = useState<Record<string, { name: string; capacity: string }>>({});
  const [form, setForm] = useState({
    name: venue.name || '',
    cityCode: venue.cityCode || '',
    latitude: venue.latitude || '',
    longitude: venue.longitude || '',
    status: venue.status || 'DRAFT',
    displayName: profile.displayName || '',
    description: profile.description || '',
    contactPhoneE164: profile.contactPhoneE164 || '',
    contactEmail: profile.contactEmail || '',
    addressLine1: profile.addressLine1 || '',
    addressLine2: profile.addressLine2 || '',
    city: profile.city || '',
    state: profile.state || '',
    postalCode: profile.postalCode || '',
    businessName: businessProfile.businessName || '',
    ownerName: businessProfile.ownerName || '',
    businessPhoneE164: businessProfile.phoneE164 || '',
    businessEmail: businessProfile.email || '',
    businessAddressLine1: businessProfile.addressLine1 || '',
    businessAddressLine2: businessProfile.addressLine2 || '',
    businessCity: businessProfile.city || '',
    businessState: businessProfile.state || '',
    businessPostalCode: businessProfile.postalCode || '',
    amenities: prettyJson(profile.amenities),
    operatingHours: prettyJson(profile.operatingHours),
    metadata: prettyJson(venue.metadata),
  });

  useEffect(() => {
    setForm({
      name: venue.name || '',
      cityCode: venue.cityCode || '',
      latitude: venue.latitude || '',
      longitude: venue.longitude || '',
      status: venue.status || 'DRAFT',
      displayName: profile.displayName || '',
      description: profile.description || '',
      contactPhoneE164: profile.contactPhoneE164 || '',
      contactEmail: profile.contactEmail || '',
      addressLine1: profile.addressLine1 || '',
      addressLine2: profile.addressLine2 || '',
      city: profile.city || '',
      state: profile.state || '',
      postalCode: profile.postalCode || '',
      businessName: businessProfile.businessName || '',
      ownerName: businessProfile.ownerName || '',
      businessPhoneE164: businessProfile.phoneE164 || '',
      businessEmail: businessProfile.email || '',
      businessAddressLine1: businessProfile.addressLine1 || '',
      businessAddressLine2: businessProfile.addressLine2 || '',
      businessCity: businessProfile.city || '',
      businessState: businessProfile.state || '',
      businessPostalCode: businessProfile.postalCode || '',
      amenities: prettyJson(profile.amenities),
      operatingHours: prettyJson(profile.operatingHours),
      metadata: prettyJson(venue.metadata),
    });
    setFacilityEdits(
      Object.fromEntries(
        (venue.facilities || []).map((facility: any) => [
          facility.id,
          {
            name: facility.name || '',
            capacity: String(facility.capacity ?? ''),
          },
        ]),
      ),
    );
    setMessage(null);
    onDirtyChange(false);
  }, [venue.id]);

  const primaryImage = useMemo(
    () => (venue.partnerImages || []).find((image: any) => image.isPrimary) || venue.partnerImages?.[0],
    [venue.partnerImages],
  );

  const updateForm = (key: string, value: string) => {
    setForm((current) => ({ ...current, [key]: value }));
    onDirtyChange(true);
  };

  const saveVenue = async (event: FormEvent) => {
    event.preventDefault();
    try {
      setSaving(true);
      setMessage(null);
      const updated = await AdminApi.updateVenue(venue.id, {
        name: form.name,
        cityCode: form.cityCode,
        latitude: form.latitude,
        longitude: form.longitude,
        status: form.status,
        metadata: parseJson(form.metadata, 'Metadata'),
        profile: {
          displayName: form.displayName,
          description: form.description,
          contactPhoneE164: form.contactPhoneE164,
          contactEmail: form.contactEmail,
          addressLine1: form.addressLine1,
          addressLine2: form.addressLine2,
          city: form.city,
          state: form.state,
          postalCode: form.postalCode,
          amenities: parseJson(form.amenities, 'Amenities'),
          operatingHours: parseJson(form.operatingHours, 'Operating hours'),
        },
        businessProfile: {
          businessName: form.businessName,
          ownerName: form.ownerName,
          phoneE164: form.businessPhoneE164,
          email: form.businessEmail,
          addressLine1: form.businessAddressLine1,
          addressLine2: form.businessAddressLine2,
          city: form.businessCity,
          state: form.businessState,
          postalCode: form.businessPostalCode,
        },
      });
      setEditMode(false);
      setMessage('Venue saved.');
      await onSaved(updated);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Failed to save venue');
    } finally {
      setSaving(false);
    }
  };

  const addImage = async (event: FormEvent) => {
    event.preventDefault();
    try {
      setMessage(null);
      if (imageFile) {
        const formData = new FormData();
        formData.set('image', imageFile);
        if (imageCaption.trim()) formData.set('caption', imageCaption.trim());
        formData.set('isPrimary', String(imagePrimary));
        await AdminApi.uploadVenueImage(venue.id, formData);
      } else {
        await AdminApi.addVenueImage(venue.id, {
          url: imageUrl.trim(),
          caption: imageCaption.trim() || undefined,
          isPrimary: imagePrimary,
        });
      }
      (event.currentTarget as HTMLFormElement).reset();
      setImageFile(null);
      setImageUrl('');
      setImageCaption('');
      setImagePrimary(false);
      await onReload();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Failed to add image');
    }
  };

  const setPrimaryImage = async (imageId: string) => {
    try {
      setMessage(null);
      await AdminApi.updateVenueImage(venue.id, imageId, { isPrimary: true });
      await onReload();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Failed to update image');
    }
  };

  const deleteImage = async (imageId: string) => {
    if (!window.confirm('Delete this venue image?')) return;
    try {
      setMessage(null);
      await AdminApi.deleteVenueImage(venue.id, imageId);
      await onReload();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Failed to delete image');
    }
  };

  const replaceImage = async (imageId: string, file: File | null) => {
    if (!file) return;
    try {
      setImageBusyId(imageId);
      setMessage(null);
      const formData = new FormData();
      formData.set('image', file);
      await AdminApi.replaceVenueImage(venue.id, imageId, formData);
      await onReload();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Failed to replace image');
    } finally {
      setImageBusyId(null);
    }
  };

  const addActivity = async (event: FormEvent) => {
    event.preventDefault();
    try {
      setMessage(null);
      await AdminApi.addVenueActivity(venue.id, activityId.trim());
      setActivityId('');
      await onReload();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Failed to add activity');
    }
  };

  const removeActivity = async (id: string) => {
    if (!window.confirm('Remove this activity from venue?')) return;
    try {
      setMessage(null);
      await AdminApi.removeVenueActivity(venue.id, id);
      await onReload();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Failed to remove activity');
    }
  };

  const updateFacilityEdit = (facilityId: string, key: string, value: string) => {
    setFacilityEdits((current) => ({
      ...current,
      [facilityId]: { ...(current[facilityId] || { name: '', capacity: '' }), [key]: value },
    }));
    onDirtyChange(true);
  };

  const saveFacility = async (facilityId: string) => {
    const edit = facilityEdits[facilityId];
    if (!edit) return;
    try {
      setMessage(null);
      await AdminApi.updateVenueFacility(venue.id, facilityId, {
        name: edit.name,
        capacity: Number(edit.capacity),
      });
      await onReload();
      onDirtyChange(false);
      setMessage('Facility saved.');
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Failed to save facility');
    }
  };

  return (
    <div>
      <header className="booking-detail-header">
        <div className="venue-title-block">
          {primaryImage ? <img className="venue-detail-image" src={imageDisplayUrl(primaryImage)} alt="" /> : <div className="user-detail-avatar">{(venue.name || 'V').slice(0, 2).toUpperCase()}</div>}
          <div>
            <h2>{profile.displayName || venue.name}</h2>
            <p>{venue.cityCode} / {venue.partner?.legalName || empty}</p>
            <div className="user-detail-chip-row">
              <span className="badge" style={{ background: getStatusColor(venue.status), color: '#050603' }}>{venue.status}</span>
              <span className="role-pill">{venue.id}</span>
            </div>
          </div>
        </div>
        <button className="btn btn-primary" type="button" onClick={() => setEditMode(true)}>
          Save
        </button>
      </header>

      <div className="user-summary-grid">
        <SummaryCard label="Facilities" value={stats.facilities ?? 0} />
        <SummaryCard label="Activities" value={stats.activities ?? 0} />
        <SummaryCard label="Bookings" value={stats.totalBookings ?? 0} />
        <SummaryCard label="Revenue" value={formatMoney(stats.revenuePaise)} />
      </div>

      {message && <div className="user-detail-notice">{message}</div>}

      {editMode ? (
        <form onSubmit={saveVenue}>
          <section className="user-detail-section">
            <h3>Edit Venue</h3>
            <div className="venue-form-grid">
              <LabelInput label="Venue name" value={form.name} onChange={(value) => updateForm('name', value)} />
              <LabelInput label="Display name" value={form.displayName} onChange={(value) => updateForm('displayName', value)} />
              <LabelInput label="City code" value={form.cityCode} onChange={(value) => updateForm('cityCode', value)} />
              <label>
                Status
                <select className="input-control" value={form.status} onChange={(event) => updateForm('status', event.target.value)}>
                  <option value="DRAFT">DRAFT</option>
                  <option value="PUBLISHED">PUBLISHED</option>
                  <option value="ARCHIVED">ARCHIVED</option>
                </select>
              </label>
              <LabelInput label="Latitude" value={form.latitude} onChange={(value) => updateForm('latitude', value)} />
              <LabelInput label="Longitude" value={form.longitude} onChange={(value) => updateForm('longitude', value)} />
              <LabelInput label="Contact phone" value={form.contactPhoneE164} onChange={(value) => updateForm('contactPhoneE164', value)} />
              <LabelInput label="Contact email" value={form.contactEmail} onChange={(value) => updateForm('contactEmail', value)} />
              <LabelInput label="Address line 1" value={form.addressLine1} onChange={(value) => updateForm('addressLine1', value)} />
              <LabelInput label="Address line 2" value={form.addressLine2} onChange={(value) => updateForm('addressLine2', value)} />
              <LabelInput label="City" value={form.city} onChange={(value) => updateForm('city', value)} />
              <LabelInput label="State" value={form.state} onChange={(value) => updateForm('state', value)} />
              <LabelInput label="Postal code" value={form.postalCode} onChange={(value) => updateForm('postalCode', value)} />
              <LabelInput label="Business name" value={form.businessName} onChange={(value) => updateForm('businessName', value)} />
              <LabelInput label="Owner name" value={form.ownerName} onChange={(value) => updateForm('ownerName', value)} />
              <LabelInput label="Business phone" value={form.businessPhoneE164} onChange={(value) => updateForm('businessPhoneE164', value)} />
              <LabelInput label="Business email" value={form.businessEmail} onChange={(value) => updateForm('businessEmail', value)} />
              <LabelInput label="Business address 1" value={form.businessAddressLine1} onChange={(value) => updateForm('businessAddressLine1', value)} />
              <LabelInput label="Business address 2" value={form.businessAddressLine2} onChange={(value) => updateForm('businessAddressLine2', value)} />
              <LabelInput label="Business city" value={form.businessCity} onChange={(value) => updateForm('businessCity', value)} />
              <LabelInput label="Business state" value={form.businessState} onChange={(value) => updateForm('businessState', value)} />
              <LabelInput label="Business postal code" value={form.businessPostalCode} onChange={(value) => updateForm('businessPostalCode', value)} />
              <label className="venue-form-wide">
                Description
                <textarea className="input-control" value={form.description} onChange={(event) => updateForm('description', event.target.value)} />
              </label>
              <label>
                Amenities JSON
                <textarea className="input-control code-textarea" value={form.amenities} onChange={(event) => updateForm('amenities', event.target.value)} />
              </label>
              <label>
                Operating hours JSON
                <textarea className="input-control code-textarea" value={form.operatingHours} onChange={(event) => updateForm('operatingHours', event.target.value)} />
              </label>
              <label className="venue-form-wide">
                Metadata JSON
                <textarea className="input-control code-textarea" value={form.metadata} onChange={(event) => updateForm('metadata', event.target.value)} />
              </label>
            </div>
            <div className="venue-actions">
              <button className="btn btn-primary" disabled={saving} type="submit">{saving ? 'Saving...' : 'Save Venue'}</button>
              <button className="btn" type="button" onClick={() => setEditMode(false)}>Cancel</button>
            </div>
          </section>
        </form>
      ) : (
        <>
          <section className="user-detail-section">
            <h3>Venue Information</h3>
            <DetailGrid items={[
              ['Venue ID', venue.id],
              ['Venue name', venue.name],
              ['Display name', profile.displayName],
              ['City code', venue.cityCode],
              ['Latitude', venue.latitude],
              ['Longitude', venue.longitude],
              ['Status', venue.status],
              ['Policy version', venue.policyVersion],
              ['Partner ID', venue.partner?.id],
              ['Partner status', venue.partner?.status],
              ['Business name', venue.partner?.businessProfile?.businessName],
              ['Owner name', venue.partner?.businessProfile?.ownerName],
            ]} />
          </section>

          <section className="user-detail-section">
            <h3>Contact / Address</h3>
            <DetailGrid items={[
              ['Phone', profile.contactPhoneE164 || venue.partner?.businessProfile?.phoneE164],
              ['Email', profile.contactEmail || venue.partner?.businessProfile?.email],
              ['Address line 1', profile.addressLine1 || venue.partner?.businessProfile?.addressLine1],
              ['Address line 2', profile.addressLine2 || venue.partner?.businessProfile?.addressLine2],
              ['City', profile.city || venue.partner?.businessProfile?.city],
              ['State', profile.state || venue.partner?.businessProfile?.state],
              ['Postal code', profile.postalCode || venue.partner?.businessProfile?.postalCode],
              ['KYC status', venue.partner?.businessProfile?.kycStatus],
            ]} />
          </section>
        </>
      )}

      <section className="user-detail-section">
        <h3>Media</h3>
        {(venue.partnerImages || []).length > 0 ? (
          <div className="venue-media-grid">
            {venue.partnerImages.map((image: any) => (
              <div className="venue-media-card" key={image.id}>
                <img src={imageDisplayUrl(image)} alt={image.caption || venue.name} />
                <div>
                  <strong>{image.caption || 'Venue image'}</strong>
                  <span>{image.isPrimary ? 'Primary' : `Sort ${image.sortOrder}`}</span>
                  {image.metadata?.cloudinaryPublicId && <span>Cloudinary</span>}
                </div>
                <div className="venue-actions">
                  <a className="btn" href={image.url} target="_blank" rel="noreferrer">View</a>
                  {!image.isPrimary && <button className="btn" type="button" onClick={() => setPrimaryImage(image.id)}>Primary</button>}
                  <label className="btn">
                    {imageBusyId === image.id ? 'Replacing...' : 'Replace'}
                    <input
                      accept="image/jpeg,image/png,image/webp,image/avif"
                      hidden
                      type="file"
                      onChange={(event) => replaceImage(image.id, event.target.files?.[0] || null)}
                    />
                  </label>
                  <button className="btn" type="button" onClick={() => deleteImage(image.id)}>Delete</button>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <p className="detail-empty">No venue images are attached.</p>
        )}
        <form className="venue-inline-form section-offset" onSubmit={addImage}>
          <input
            accept="image/jpeg,image/png,image/webp,image/avif"
            className="input-control"
            type="file"
            onChange={(event) => setImageFile(event.target.files?.[0] || null)}
          />
          <input className="input-control" placeholder="https:// image URL" value={imageUrl} onChange={(event) => setImageUrl(event.target.value)} />
          <input className="input-control" placeholder="Caption" value={imageCaption} onChange={(event) => setImageCaption(event.target.value)} />
          <label className="checkbox-row">
            <input type="checkbox" checked={imagePrimary} onChange={(event) => setImagePrimary(event.target.checked)} />
            Primary
          </label>
          <button className="btn btn-primary" type="submit">Add Image</button>
        </form>
      </section>

      <section className="user-detail-section">
        <h3>Activities</h3>
        {(venue.activities || []).length > 0 ? (
          <div className="compact-list">
            {venue.activities.map((item: any) => (
              <div className="compact-list-item" key={item.activity.id}>
                <div>
                  <strong>{item.activity.name}</strong>
                  <span>{item.activity.id} / {item.activity.sportCode} / {item.activity.type}</span>
                </div>
                <button className="btn" type="button" onClick={() => removeActivity(item.activity.id)}>Remove</button>
              </div>
            ))}
          </div>
        ) : (
          <p className="detail-empty">No activities assigned.</p>
        )}
        <form className="venue-inline-form section-offset" onSubmit={addActivity}>
          <input className="input-control" placeholder="Activity UUID" value={activityId} onChange={(event) => setActivityId(event.target.value)} />
          <button className="btn btn-primary" type="submit">Add Activity</button>
        </form>
      </section>

      <section className="user-detail-section">
        <h3>Facilities / Slots</h3>
        {(venue.facilities || []).length > 0 ? (
          <div className="venue-facility-editor">
            {venue.facilities.map((facility: any) => {
              const nextSlot = facility.slots?.[0];
              const edit = facilityEdits[facility.id] || {
                name: facility.name || '',
                capacity: String(facility.capacity ?? ''),
              };
              return (
                <div className="venue-facility-row" key={facility.id}>
                  <div className="venue-facility-summary">
                    <strong>{facility.name}</strong>
                    <span>{facility.activity?.name || empty} / Capacity {facility.capacity ?? empty} / Slots {facility._count?.slots ?? 0}</span>
                    <span>Next: {formatDateTime(nextSlot?.startsAt)}</span>
                    <span>{nextSlot ? formatMoney(nextSlot.pricePaise) : empty}</span>
                  </div>
                  <LabelInput label="Facility name" value={edit.name} onChange={(value) => updateFacilityEdit(facility.id, 'name', value)} />
                  <LabelInput label="Capacity" value={edit.capacity} onChange={(value) => updateFacilityEdit(facility.id, 'capacity', value)} />
                  <button className="btn btn-primary" type="button" onClick={() => saveFacility(facility.id)}>
                    Save Facility
                  </button>
                </div>
              );
            })}
          </div>
        ) : (
          <p className="detail-empty">No facilities available.</p>
        )}
      </section>

      <section className="user-detail-section">
        <h3>Bookings / Reviews</h3>
        <DetailGrid items={[
          ['Confirmed bookings', stats.confirmedBookings],
          ['Completed bookings', stats.completedBookings],
          ['Cancelled bookings', stats.cancelledBookings],
          ['Upcoming bookings', stats.upcomingBookings],
          ['Saved by users', stats.savedBy],
          ['Average rating', stats.averageRating ? Number(stats.averageRating).toFixed(1) : empty],
          ['Total reviews', stats.totalReviews],
          ['Total revenue', formatMoney(stats.revenuePaise)],
        ]} />
        <div className="venue-split-list section-offset">
          <RecentList title="Recent bookings" items={details.recentBookings || []} render={(booking: any) => (
            <>
              <strong>{booking.publicCode || booking.id}</strong>
              <span>{booking.user?.name || empty} / {booking.status} / {formatMoney(booking.totalPaise)}</span>
            </>
          )} />
          <RecentList title="Recent reviews" items={details.recentReviews || []} render={(review: any) => (
            <>
              <strong>{review.rating} / 5</strong>
              <span>{review.user?.name || empty} / {review.status} / {review.body || empty}</span>
            </>
          )} />
        </div>
      </section>

      <section className="user-detail-section">
        <h3>Admin / Audit</h3>
        <DetailGrid items={[
          ['Description', profile.description],
          ['Amenities', prettyJson(profile.amenities)],
          ['Operating hours', prettyJson(profile.operatingHours)],
          ['Metadata', prettyJson(venue.metadata)],
        ]} />
        {(details.auditEvents || []).length > 0 && (
          <div className="timeline-list section-offset">
            {details.auditEvents.map((event: any) => (
              <div className="timeline-item" key={event.id}>
                <span className="timeline-dot" />
                <div>
                  <strong>{event.action}</strong>
                  <p>{formatDateTime(event.createdAt)}</p>
                  {event.actorId && <p>Actor {event.actorId}</p>}
                </div>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}

function LabelInput({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) {
  return (
    <label>
      {label}
      <input className="input-control" value={value} onChange={(event) => onChange(event.target.value)} />
    </label>
  );
}

function RecentList({ title, items, render }: { title: string; items: any[]; render: (item: any) => ReactNode }) {
  return (
    <div>
      <h4>{title}</h4>
      {items.length > 0 ? (
        <div className="compact-list">
          {items.map((item) => (
            <div className="compact-list-item" key={item.id}>
              <div>{render(item)}</div>
            </div>
          ))}
        </div>
      ) : (
        <p className="detail-empty">{empty}</p>
      )}
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

function VenueDetailsSkeleton() {
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

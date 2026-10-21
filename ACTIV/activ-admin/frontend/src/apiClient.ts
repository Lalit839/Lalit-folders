import axios from 'axios';

const normalizeBaseUrl = (url: string) => url.replace(/\/+$/, '');

const BASE_URL = normalizeBaseUrl(
  import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000/api/v1',
);
const WEBSITE_API_BASE_URL = normalizeBaseUrl(
  import.meta.env.VITE_WEBSITE_API_BASE_URL || `${BASE_URL}/website`,
);

export const apiClient = axios.create({
  baseURL: BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

let refreshPromise: Promise<string | null> | null = null;

type ListResponse<T = any> = {
  items: T[];
  total: number;
};

type LoginResponse = {
  accessToken: string;
  refreshToken: string;
};

export type WebsiteContact = {
  id: string;
  fullName: string;
  email: string;
  phone?: string;
  message: string;
  createdAt: string;
};

export type WebsiteFaq = {
  id: string;
  category: string;
  question: string;
  answer: string;
};

export type WebsiteSocialLinks = Record<
  'instagram' | 'linkedin' | 'facebook' | 'youtube' | 'x',
  string
>;

export type WebsiteAdminProfile = {
  name: string;
  email: string;
  role: string;
};

const dataRequest = <T>(request: Promise<unknown>) => request as Promise<T>;

const websiteRequest = async <T>(
  path: string,
  init?: RequestInit,
): Promise<T> => {
  const endpointPath = path.startsWith('/') ? path : `/${path}`;
  const token = localStorage.getItem('admin_access_token');
  const response = await fetch(`${WEBSITE_API_BASE_URL}${endpointPath}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(init?.headers || {}),
    },
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(data.message || 'Website admin request failed');
  }
  return (data?.data ?? data) as T;
};

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_access_token');
  if (token && config.headers) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

apiClient.interceptors.response.use(
  (response) => {
    return response.data?.data ?? response.data;
  },
  async (error) => {
    const originalRequest = error.config;
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      try {
        refreshPromise ??= refreshAdminToken();
        const newAccess = await refreshPromise.finally(() => {
          refreshPromise = null;
        });

        if (newAccess) {
          originalRequest.headers.Authorization = `Bearer ${newAccess}`;
          const retryRes = await axios(originalRequest);
          return retryRes.data?.data ?? retryRes.data;
        }
      } catch (e) {
        localStorage.removeItem('admin_access_token');
        localStorage.removeItem('admin_refresh_token');
        window.location.href = '/login';
      }
    }

    // Format error message
    let message = 'Request failed';
    const errData = error.response?.data;
    if (errData) {
      if (
        errData.error &&
        Array.isArray(errData.error) &&
        errData.error.length > 0
      ) {
        const first = errData.error[0];
        if (first.constraints) {
          message = Object.values(first.constraints)[0] as string;
        } else if (first.message) {
          message = first.message;
        } else if (typeof first === 'string') {
          message = first;
        }
      } else if (errData.message) {
        message = errData.message;
      }
    }
    return Promise.reject(new Error(message));
  }
);

async function refreshAdminToken(): Promise<string | null> {
  const refreshToken = localStorage.getItem('admin_refresh_token');
  if (!refreshToken) return null;

  const { data } = await axios.post(`${BASE_URL}/auth/token/refresh`, {
    refreshToken,
  });
  const newAccess = data?.data?.accessToken ?? data?.accessToken;
  const newRefresh = data?.data?.refreshToken ?? data?.refreshToken;

  if (!newAccess) return null;
  localStorage.setItem('admin_access_token', newAccess);
  if (newRefresh) localStorage.setItem('admin_refresh_token', newRefresh);
  return newAccess;
}

export const AdminApi = {
  // Auth
  login: (email: string, password: string) => dataRequest<LoginResponse>(apiClient.post('/admin/auth/login', { email, password })),
  
  // Dashboard
  getDashboardOverview: () => dataRequest<any>(apiClient.get('/admin/dashboard/overview')),
  getDashboardRevenue: (days: number = 30) => dataRequest<any[]>(apiClient.get(`/admin/dashboard/revenue?days=${days}`)),
  getDashboardBookings: (days: number = 30) => dataRequest<any[]>(apiClient.get(`/admin/dashboard/bookings?days=${days}`)),

  // Users
  getUsers: (params?: any) => dataRequest<ListResponse>(apiClient.get('/admin/users', { params })),
  getUserDetails: (id: string) => dataRequest<any>(apiClient.get(`/admin/users/${id}`)),
  updateUserStatus: (id: string, status: string) => dataRequest<any>(apiClient.patch(`/admin/users/${id}/status`, { status })),
  updateUserRole: (id: string, role: string | null) => dataRequest<any>(apiClient.patch(`/admin/users/${id}/role`, { role })),
  revokeUserSessions: (id: string) => dataRequest<any>(apiClient.post(`/admin/users/${id}/revoke-sessions`)),

  // Bookings
  getBookings: (params?: any) => dataRequest<ListResponse>(apiClient.get('/admin/bookings', { params })),
  getBookingDetails: (id: string) => dataRequest<any>(apiClient.get(`/admin/bookings/${id}`)),
  cancelBooking: (id: string, reason: string) => dataRequest<any>(apiClient.post(`/admin/bookings/${id}/cancel`, { reason })),
  initiateBookingRefund: (id: string, payload: { amountPaise: number; paymentId?: string; reason?: string; status?: string; providerRef?: string }) => dataRequest<any>(apiClient.post(`/admin/bookings/${id}/refunds`, payload)),
  updateBookingRefund: (bookingId: string, refundId: string, payload: { amountPaise?: number; reason?: string; status?: string; providerRef?: string }) => dataRequest<any>(apiClient.patch(`/admin/bookings/${bookingId}/refunds/${refundId}`, payload)),

  // Venues
  getVenues: (params?: any) => dataRequest<ListResponse>(apiClient.get('/admin/venues', { params })),
  getVenueDetails: (id: string) => dataRequest<any>(apiClient.get(`/admin/venues/${id}`)),
  updateVenue: (id: string, payload: any) => dataRequest<any>(apiClient.patch(`/admin/venues/${id}`, payload)),
  updateVenueStatus: (id: string, status: string) => dataRequest<any>(apiClient.patch(`/admin/venues/${id}/status`, { status })),
  addVenueImage: (id: string, payload: { url: string; caption?: string; sortOrder?: number; isPrimary?: boolean; metadata?: any }) => dataRequest<any>(apiClient.post(`/admin/venues/${id}/images`, payload)),
  uploadVenueImage: (id: string, form: FormData) => dataRequest<any>(apiClient.post(`/admin/venues/${id}/images`, form, { headers: { 'Content-Type': 'multipart/form-data' } })),
  updateVenueImage: (venueId: string, imageId: string, payload: { url?: string; caption?: string; sortOrder?: number; isPrimary?: boolean; metadata?: any }) => dataRequest<any>(apiClient.patch(`/admin/venues/${venueId}/images/${imageId}`, payload)),
  replaceVenueImage: (venueId: string, imageId: string, form: FormData) => dataRequest<any>(apiClient.patch(`/admin/venues/${venueId}/images/${imageId}`, form, { headers: { 'Content-Type': 'multipart/form-data' } })),
  deleteVenueImage: (venueId: string, imageId: string) => dataRequest<any>(apiClient.delete(`/admin/venues/${venueId}/images/${imageId}`)),
  updateVenueFacility: (venueId: string, facilityId: string, payload: { name?: string; capacity?: number; activityId?: string }) => dataRequest<any>(apiClient.patch(`/admin/venues/${venueId}/facilities/${facilityId}`, payload)),
  addVenueActivity: (venueId: string, activityId: string) => dataRequest<any>(apiClient.post(`/admin/venues/${venueId}/activities/${activityId}`)),
  removeVenueActivity: (venueId: string, activityId: string) => dataRequest<any>(apiClient.delete(`/admin/venues/${venueId}/activities/${activityId}`)),

  // Payments & Refunds
  getPayments: (params?: any) => dataRequest<ListResponse>(apiClient.get('/admin/payments', { params })),
  getRefunds: (params?: any) => dataRequest<ListResponse>(apiClient.get('/admin/refunds', { params })),

  // Support
  getSupportTickets: (params?: any) => dataRequest<ListResponse>(apiClient.get('/admin/support/tickets', { params })),
  updateTicketStatus: (id: string, status: string) => dataRequest<any>(apiClient.patch(`/admin/support/tickets/${id}/status`, { status })),

  // Content/Catalog
  getCoupons: (params?: any) => dataRequest<ListResponse>(apiClient.get('/admin/coupons', { params })),
  getFaqs: (params?: any) => dataRequest<ListResponse>(apiClient.get('/admin/content/faqs', { params })),


  // Helpers
  getExportUrl: (path: string, params?: Record<string, string>) => {
    const query = new URLSearchParams(params || {}).toString();
    return `${BASE_URL}${path}${query ? '?' + query : ''}`;
  },
  downloadCsv: async (path: string, filename: string, params?: Record<string, string>) => {
    const url = AdminApi.getExportUrl(path, params);
    const token = localStorage.getItem('admin_access_token');
    const res = await fetch(url, { headers: { Authorization: `Bearer ${token}` }});
    if (res.ok) {
      const blob = await res.blob();
      const objectUrl = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = objectUrl;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(objectUrl);
    }
  }
};

export const WebsiteAdminApi = {
  getContacts: () => websiteRequest<WebsiteContact[]>('/contacts'),
  getFaqs: () => websiteRequest<WebsiteFaq[]>('/faqs'),
  createFaq: (faq: Omit<WebsiteFaq, 'id'>) => websiteRequest<WebsiteFaq>('/faqs', {
    method: 'POST',
    body: JSON.stringify(faq),
  }),
  updateFaq: (faq: WebsiteFaq) => websiteRequest<WebsiteFaq>(`/faqs/${faq.id}`, {
    method: 'PUT',
    body: JSON.stringify(faq),
  }),
  deleteFaq: (id: string) => websiteRequest<{ success: boolean }>(`/faqs/${id}`, {
    method: 'DELETE',
  }),
  getSocialLinks: () => websiteRequest<WebsiteSocialLinks>('/social-links'),
  updateSocialLinks: (links: WebsiteSocialLinks) => websiteRequest<WebsiteSocialLinks>('/social-links', {
    method: 'PUT',
    body: JSON.stringify(links),
  }),
  getProfile: () => websiteRequest<WebsiteAdminProfile>('/admin/profile'),
};

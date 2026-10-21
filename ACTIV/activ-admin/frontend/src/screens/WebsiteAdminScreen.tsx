import { useEffect, useMemo, useState, type FormEvent } from 'react';
import {
  ExternalLink,
  FileQuestion,
  Inbox,
  Pencil,
  Save,
  Settings,
  ShieldCheck,
  Trash2,
} from 'lucide-react';
import {
  WebsiteAdminApi,
  type WebsiteAdminProfile,
  type WebsiteContact,
  type WebsiteFaq,
  type WebsiteSocialLinks,
} from '../apiClient';

type WebsiteAdminTab = 'messages' | 'faqs' | 'settings' | 'profile';

const emptyLinks: WebsiteSocialLinks = {
  instagram: '#',
  linkedin: '#',
  facebook: '#',
  youtube: '#',
  x: '#',
};

const blankFaq = {
  category: 'Players',
  question: '',
  answer: '',
};

const tabs: Array<{ id: WebsiteAdminTab; label: string; icon: typeof Inbox }> = [
  { id: 'messages', label: 'Messages', icon: Inbox },
  { id: 'faqs', label: 'FAQs', icon: FileQuestion },
  { id: 'settings', label: 'Social Links', icon: Settings },
  { id: 'profile', label: 'Profile', icon: ShieldCheck },
];

export default function WebsiteAdminScreen() {
  const [activeTab, setActiveTab] = useState<WebsiteAdminTab>('messages');
  const [contacts, setContacts] = useState<WebsiteContact[]>([]);
  const [faqs, setFaqs] = useState<WebsiteFaq[]>([]);
  const [links, setLinks] = useState<WebsiteSocialLinks>(emptyLinks);
  const [profile, setProfile] = useState<WebsiteAdminProfile | null>(null);
  const [newFaq, setNewFaq] = useState(blankFaq);
  const [editingFaq, setEditingFaq] = useState<WebsiteFaq | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [notice, setNotice] = useState('');
  const [error, setError] = useState('');

  const faqGroups = useMemo(() => (
    faqs.reduce<Record<string, WebsiteFaq[]>>((groups, faq) => {
      groups[faq.category] = [...(groups[faq.category] || []), faq];
      return groups;
    }, {})
  ), [faqs]);

  useEffect(() => {
    const loadWebsiteAdmin = async () => {
      try {
        setLoading(true);
        setError('');

        const [contactsData, linksData, profileData, faqsData] = await Promise.all([
          WebsiteAdminApi.getContacts(),
          WebsiteAdminApi.getSocialLinks(),
          WebsiteAdminApi.getProfile(),
          WebsiteAdminApi.getFaqs(),
        ]);

        setContacts(contactsData);
        setLinks({ ...emptyLinks, ...linksData });
        setProfile(profileData);
        setFaqs(faqsData);
      } catch (err: any) {
        setError(err.message || 'Website admin backend is unavailable.');
      } finally {
        setLoading(false);
      }
    };

    loadWebsiteAdmin();
  }, []);

  const showNotice = (message: string) => {
    setNotice(message);
    window.setTimeout(() => setNotice(''), 3500);
  };

  const addFaq = async (event: FormEvent) => {
    event.preventDefault();
    try {
      setSaving(true);
      const created = await WebsiteAdminApi.createFaq(newFaq);
      setFaqs((items) => [...items, created]);
      setNewFaq(blankFaq);
      showNotice('FAQ added successfully.');
    } catch (err: any) {
      setError(err.message || 'Could not add FAQ.');
    } finally {
      setSaving(false);
    }
  };

  const updateFaq = async (event: FormEvent) => {
    event.preventDefault();
    if (!editingFaq) return;

    try {
      setSaving(true);
      const updated = await WebsiteAdminApi.updateFaq(editingFaq);
      setFaqs((items) => items.map((item) => (item.id === updated.id ? updated : item)));
      setEditingFaq(null);
      showNotice('FAQ updated successfully.');
    } catch (err: any) {
      setError(err.message || 'Could not update FAQ.');
    } finally {
      setSaving(false);
    }
  };

  const deleteFaq = async (id: string) => {
    try {
      setSaving(true);
      await WebsiteAdminApi.deleteFaq(id);
      setFaqs((items) => items.filter((item) => item.id !== id));
      showNotice('FAQ deleted successfully.');
    } catch (err: any) {
      setError(err.message || 'Could not delete FAQ.');
    } finally {
      setSaving(false);
    }
  };

  const saveLinks = async (event: FormEvent) => {
    event.preventDefault();
    try {
      setSaving(true);
      const updated = await WebsiteAdminApi.updateSocialLinks(links);
      setLinks({ ...emptyLinks, ...updated });
      showNotice('Social links saved.');
    } catch (err: any) {
      setError(err.message || 'Could not save social links.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) return <div className="loading-state">Loading website admin...</div>;

  return (
    <div className="website-admin-page">
      <div className="page-header">
        <div>
          <h1 className="page-title">Website Admin</h1>
          <p>Manage website messages, FAQs, footer links, and admin profile.</p>
        </div>
        <a className="btn btn-primary" href="http://localhost:5000/" target="_blank" rel="noreferrer">
          <ExternalLink size={18} /> Backend
        </a>
      </div>

      {error && <div className="dashboard-error">{error}</div>}
      {notice && <div className="website-notice">{notice}</div>}

      <div className="website-admin-tabs">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.id}
              className={`website-admin-tab ${activeTab === tab.id ? 'active' : ''}`}
              onClick={() => {
                setActiveTab(tab.id);
                setError('');
                setNotice('');
              }}
              type="button"
            >
              <Icon size={18} /> {tab.label}
            </button>
          );
        })}
      </div>

      {activeTab === 'messages' && (
        <section className="website-section">
          <div className="section-title-row">
            <div>
              <h2>Website messages</h2>
              <p>Contact submissions from the website support form.</p>
            </div>
            <span className="website-count">{contacts.length} total</span>
          </div>

          {contacts.length === 0 ? (
            <WebsiteEmpty text="No messages yet." />
          ) : (
            <div className="website-message-list">
              {contacts.map((contact) => (
                <article key={contact.id} className="glass-card website-message-card">
                  <div className="message-head">
                    <div>
                      <h3>{contact.fullName}</h3>
                      <p>{contact.email}{contact.phone ? ` / ${contact.phone}` : ''}</p>
                    </div>
                    <time>{new Date(contact.createdAt).toLocaleString()}</time>
                  </div>
                  <p className="message-body">{contact.message}</p>
                </article>
              ))}
            </div>
          )}
        </section>
      )}

      {activeTab === 'faqs' && (
        <section className="website-section">
          <div className="section-title-row">
            <div>
              <h2>Website FAQs</h2>
              <p>Add, edit, and delete FAQ entries shown on the public website.</p>
            </div>
            <span className="website-count">{faqs.length} total</span>
          </div>

          <form className="glass-card website-form" onSubmit={addFaq}>
            <div className="website-form-grid">
              <label>
                Category
                <select
                  className="input-control"
                  value={newFaq.category}
                  onChange={(event) => setNewFaq({ ...newFaq, category: event.target.value })}
                >
                  <option value="Players">Players</option>
                  <option value="Venue partners">Venue partners</option>
                  <option value="Platform & Support">Platform & Support</option>
                </select>
              </label>
              <label>
                Question
                <input
                  className="input-control"
                  required
                  value={newFaq.question}
                  onChange={(event) => setNewFaq({ ...newFaq, question: event.target.value })}
                  placeholder="e.g. How do I book?"
                />
              </label>
            </div>
            <label>
              Answer
              <textarea
                className="input-control"
                required
                rows={3}
                value={newFaq.answer}
                onChange={(event) => setNewFaq({ ...newFaq, answer: event.target.value })}
                placeholder="Answer here..."
              />
            </label>
            <button className="btn btn-primary" disabled={saving} type="submit">
              <Save size={18} /> Add FAQ
            </button>
          </form>

          {Object.keys(faqGroups).length === 0 ? (
            <WebsiteEmpty text="No FAQs yet." />
          ) : (
            <div className="website-faq-groups">
              {Object.entries(faqGroups).map(([category, categoryFaqs]) => (
                <div key={category} className="website-faq-group">
                  <h3>{category}</h3>
                  {categoryFaqs.map((faq) => (
                    <article key={faq.id} className="glass-card website-faq-card">
                      {editingFaq?.id === faq.id ? (
                        <form className="website-edit-form" onSubmit={updateFaq}>
                          <select
                            className="input-control"
                            value={editingFaq.category}
                            onChange={(event) => setEditingFaq({ ...editingFaq, category: event.target.value })}
                          >
                            <option value="Players">Players</option>
                            <option value="Venue partners">Venue partners</option>
                            <option value="Platform & Support">Platform & Support</option>
                          </select>
                          <input
                            className="input-control"
                            required
                            value={editingFaq.question}
                            onChange={(event) => setEditingFaq({ ...editingFaq, question: event.target.value })}
                          />
                          <textarea
                            className="input-control"
                            required
                            rows={3}
                            value={editingFaq.answer}
                            onChange={(event) => setEditingFaq({ ...editingFaq, answer: event.target.value })}
                          />
                          <div className="website-actions">
                            <button className="btn btn-primary" disabled={saving} type="submit">Save</button>
                            <button className="btn" onClick={() => setEditingFaq(null)} type="button">Cancel</button>
                          </div>
                        </form>
                      ) : (
                        <>
                          <div className="faq-head">
                            <h4>{faq.question}</h4>
                            <div className="website-actions">
                              <button className="icon-btn" onClick={() => setEditingFaq(faq)} title="Edit FAQ" type="button">
                                <Pencil size={16} />
                              </button>
                              <button className="icon-btn danger" onClick={() => deleteFaq(faq.id)} title="Delete FAQ" type="button">
                                <Trash2 size={16} />
                              </button>
                            </div>
                          </div>
                          <p>{faq.answer}</p>
                        </>
                      )}
                    </article>
                  ))}
                </div>
              ))}
            </div>
          )}
        </section>
      )}

      {activeTab === 'settings' && (
        <section className="website-section">
          <div className="section-title-row">
            <div>
              <h2>Footer social links</h2>
              <p>These links are consumed by the website footer.</p>
            </div>
          </div>
          <form className="glass-card website-form compact-form" onSubmit={saveLinks}>
            {Object.keys(links).map((key) => (
              <label key={key}>
                {key}
                <input
                  className="input-control"
                  value={links[key as keyof WebsiteSocialLinks]}
                  onChange={(event) => setLinks({ ...links, [key]: event.target.value })}
                  placeholder={`https://${key}.com/activ`}
                />
              </label>
            ))}
            <button className="btn btn-primary" disabled={saving} type="submit">
              <Save size={18} /> Save social links
            </button>
          </form>
        </section>
      )}

      {activeTab === 'profile' && (
        <section className="website-section">
          <div className="section-title-row">
            <div>
              <h2>Website admin profile</h2>
              <p>Profile data loaded from the website backend.</p>
            </div>
          </div>
          <div className="glass-card website-profile-card">
            <div className="profile-avatar">A</div>
            <div>
              <h3>{profile?.name || 'ACTIV Administrator'}</h3>
              <p>{profile?.email || 'adminactiv@gmail.com'}</p>
              <span>{profile?.role || 'Super Admin'}</span>
            </div>
          </div>
        </section>
      )}
    </div>
  );
}

function WebsiteEmpty({ text }: { text: string }) {
  return <div className="website-empty">{text}</div>;
}

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

export type WebsiteSocialLinks = Record<'instagram' | 'linkedin' | 'facebook' | 'youtube' | 'x', string>;

export type WebsiteData = {
  faqs: WebsiteFaq[];
  contacts: WebsiteContact[];
  socialLinks: WebsiteSocialLinks;
  adminProfile: {
    name: string;
    email: string;
    role: string;
  };
};

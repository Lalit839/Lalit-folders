import { Injectable, NotFoundException } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { WebsiteData, WebsiteFaq, WebsiteSocialLinks } from "./website.types";

const dataFile = path.resolve(process.cwd(), "data/site-data.json");

const defaultWebsiteData: WebsiteData = {
  faqs: [
    {
      id: "1",
      category: "Players",
      question: "When will the ACTIV app be available?",
      answer:
        "ACTIV is rolling out across major cities soon. Download the app on iOS or Android to check availability in your area and pre-register your account.",
    },
    {
      id: "2",
      category: "Players",
      question: "How does ACTIV ensure venue quality?",
      answer:
        "Every single venue on ACTIV is physically reviewed and verified by our team before listing to ensure real photos, proper equipment, and accurate live availability.",
    },
    {
      id: "3",
      category: "Players",
      question: "What happens if I'm running late for a booking?",
      answer:
        "You can view your booking details and directly contact the venue manager through the app to inform them of any minor schedule changes.",
    },
    {
      id: "4",
      category: "Players",
      question: "Can I cancel or get a refund on a booking?",
      answer:
        "Yes, cancellations made within the permitted venue window are fully refunded back to your source account instantly.",
    },
    {
      id: "5",
      category: "Players",
      question: "Can I share my booking with friends?",
      answer:
        "Absolutely! You can share booking confirmation links directly via WhatsApp or copy details to share with your group instantly.",
    },
    {
      id: "6",
      category: "Players",
      question: "How do I find only verified venues near me?",
      answer:
        "All venues listed on ACTIV are pre-vetted. Use location permissions or search by your preferred area to see active spaces immediately.",
    },
    {
      id: "7",
      category: "Venue partners",
      question: "What types of venues can partner with ACTIV?",
      answer:
        "Turfs, badminton courts, pickleball arenas, fitness studios, yoga spaces, gyms, and sports complexes of all sizes.",
    },
    {
      id: "8",
      category: "Venue partners",
      question: "What's the commission structure on ACTIV?",
      answer:
        "We maintain transparent per-booking models with zero setup costs or hidden subscription overheads.",
    },
    {
      id: "9",
      category: "Venue partners",
      question: "How long does the approval process take?",
      answer:
        "Most venues go live within 24 hours following quick verification and slot configuration by our onboarding team.",
    },
    {
      id: "10",
      category: "Venue partners",
      question: "Can I control my pricing and availability?",
      answer:
        "Yes, you have full real-time control over slot pricing, peak hours, blackout dates, and court availability via your partner dashboard.",
    },
    {
      id: "11",
      category: "Venue partners",
      question: "How do I receive payments for bookings?",
      answer:
        "Payments are processed securely online and settled directly to your registered bank account on a scheduled cycle.",
    },
    {
      id: "12",
      category: "Venue partners",
      question: "What support does ACTIV provide partners?",
      answer:
        "Dedicated account management, technical assistance, marketing boost in local search results, and 24/7 operational support.",
    },
    {
      id: "13",
      category: "Platform & Support",
      question: "Which cities is ACTIV launching in?",
      answer:
        "We are actively expanding across Mumbai, Bengaluru, Hyderabad, Delhi-NCR, Pune, and major tier-1 sports hubs.",
    },
    {
      id: "14",
      category: "Platform & Support",
      question: "How do I cancel or reschedule a booking?",
      answer:
        "Navigate to your bookings tab in the app, select the active reservation, and tap modify or cancel according to venue policy.",
    },
    {
      id: "15",
      category: "Platform & Support",
      question: "What happens if a venue cancels on me?",
      answer:
        "In rare cases of venue-side cancellations, you receive an immediate full refund plus priority re-booking options.",
    },
    {
      id: "16",
      category: "Platform & Support",
      question: "How do I reach the ACTIV team?",
      answer:
        "You can reach us anytime at Support@activ.live or submit the direct contact form below for prompt assistance.",
    },
  ],
  contacts: [],
  socialLinks: {
    instagram: "#",
    linkedin: "#",
    facebook: "#",
    youtube: "#",
    x: "#",
  },
  adminProfile: {
    name: "ACTIV Administrator",
    email: "adminactiv@gmail.com",
    role: "Super Admin",
  },
};

@Injectable()
export class WebsiteService {
  async getProfile() {
    const data = await this.readData();
    return data.adminProfile;
  }

  async listContacts() {
    const data = await this.readData();
    return data.contacts;
  }

  async createContact(input: {
    fullName: string;
    email: string;
    phone?: string;
    message: string;
  }) {
    const data = await this.readData();
    const contact = {
      id: randomUUID(),
      fullName: input.fullName.trim(),
      email: input.email.trim(),
      phone: input.phone?.trim() || "",
      message: input.message.trim(),
      createdAt: new Date().toISOString(),
    };

    data.contacts = [contact, ...data.contacts];
    await this.writeData(data);
    return contact;
  }

  async listFaqs() {
    const data = await this.readData();
    return data.faqs;
  }

  async createFaq(input: Omit<WebsiteFaq, "id">) {
    const data = await this.readData();
    const faq = {
      id: randomUUID(),
      category: input.category.trim(),
      question: input.question.trim(),
      answer: input.answer.trim(),
    };

    data.faqs = [...data.faqs, faq];
    await this.writeData(data);
    return faq;
  }

  async updateFaq(id: string, input: Omit<WebsiteFaq, "id">) {
    const data = await this.readData();
    const index = data.faqs.findIndex((faq) => faq.id === id);
    if (index === -1) throw new NotFoundException("FAQ not found.");

    data.faqs[index] = {
      id,
      category: input.category.trim(),
      question: input.question.trim(),
      answer: input.answer.trim(),
    };
    await this.writeData(data);
    return data.faqs[index];
  }

  async deleteFaq(id: string) {
    const data = await this.readData();
    data.faqs = data.faqs.filter((faq) => faq.id !== id);
    await this.writeData(data);
    return { success: true };
  }

  async getSocialLinks() {
    const data = await this.readData();
    return data.socialLinks;
  }

  async updateSocialLinks(input: WebsiteSocialLinks) {
    const data = await this.readData();
    data.socialLinks = {
      instagram: input.instagram.trim(),
      linkedin: input.linkedin.trim(),
      facebook: input.facebook.trim(),
      youtube: input.youtube.trim(),
      x: input.x.trim(),
    };
    await this.writeData(data);
    return data.socialLinks;
  }

  private async readData(): Promise<WebsiteData> {
    try {
      const data = JSON.parse(
        await readFile(dataFile, "utf8"),
      ) as Partial<WebsiteData>;
      return {
        ...defaultWebsiteData,
        ...data,
        faqs: data.faqs || defaultWebsiteData.faqs,
        contacts: data.contacts || defaultWebsiteData.contacts,
        socialLinks: {
          ...defaultWebsiteData.socialLinks,
          ...(data.socialLinks || {}),
        },
        adminProfile: {
          ...defaultWebsiteData.adminProfile,
          ...(data.adminProfile || {}),
        },
      };
    } catch {
      await this.writeData(defaultWebsiteData);
      return defaultWebsiteData;
    }
  }

  private async writeData(data: WebsiteData): Promise<void> {
    await mkdir(path.dirname(dataFile), { recursive: true });
    await writeFile(dataFile, JSON.stringify(data, null, 2));
  }
}

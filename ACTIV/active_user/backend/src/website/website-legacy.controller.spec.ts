import { WebsiteLegacyController } from "./website-legacy.controller";
import { WebsiteService } from "./website.service";

describe("WebsiteLegacyController", () => {
  const website = {
    getProfile: jest.fn(),
    listContacts: jest.fn(),
    createContact: jest.fn(),
    listFaqs: jest.fn(),
    createFaq: jest.fn(),
    updateFaq: jest.fn(),
    deleteFaq: jest.fn(),
    getSocialLinks: jest.fn(),
    updateSocialLinks: jest.fn(),
  } as unknown as jest.Mocked<WebsiteService>;

  let controller: WebsiteLegacyController;

  beforeEach(() => {
    jest.clearAllMocks();
    controller = new WebsiteLegacyController(website);
  });

  it("serves FAQs using the live Vercel website response shape", async () => {
    const faqs = [
      {
        id: "1",
        category: "Players",
        question: "Question?",
        answer: "Answer.",
      },
    ];
    website.listFaqs.mockResolvedValue(faqs);

    await expect(controller.listFaqs()).resolves.toBe(faqs);
    expect(website.listFaqs).toHaveBeenCalledTimes(1);
  });

  it("captures contact submissions from the live website form", async () => {
    const input = {
      fullName: "ACTIV User",
      email: "user@example.com",
      phone: "9999999999",
      message: "Need help",
    };
    const contact = {
      ...input,
      id: "00000000-0000-4000-8000-000000000001" as `${string}-${string}-${string}-${string}-${string}`,
      createdAt: "2026-09-28T00:00:00.000Z",
    };
    website.createContact.mockResolvedValue(contact);

    await expect(controller.createContact(input)).resolves.toBe(contact);
    expect(website.createContact).toHaveBeenCalledWith(input);
  });

  it("updates social links used by the website footer", async () => {
    const links = {
      instagram: "https://instagram.com/activ",
      linkedin: "https://linkedin.com/company/activ",
      facebook: "https://facebook.com/activ",
      youtube: "https://youtube.com/@ACTIVMinds",
      x: "https://x.com/activ",
    };
    website.updateSocialLinks.mockResolvedValue(links);

    await expect(controller.updateSocialLinks(links)).resolves.toBe(links);
    expect(website.updateSocialLinks).toHaveBeenCalledWith(links);
  });
});

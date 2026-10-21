import { Controller, Get, Param } from "@nestjs/common";
import { ContentService } from "./content.service";

@Controller("content")
export class ContentController {
  constructor(private readonly content: ContentService) {}

  @Get("policies/:type")
  getPolicy(@Param("type") type: string) {
    return this.content.getPolicy(type);
  }

  @Get("faqs")
  getFaqs() {
    return this.content.getFaqs();
  }
}

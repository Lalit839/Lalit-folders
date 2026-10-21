import { Injectable, Logger } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";

/**
 * ACTIV WhatsApp notifications demo-mode — pinnedWhatsappChannelService.
 *
 * Environment wiring (backend/.env.development):
 *   MSG91_WHATSAPP_ENABLED=false   <- demo mode (default)
 *   MSG91_WHATSAPP_TEMPLATE_ID=    <- live template once provided
 *
 * Demo mode never makes an outbound call; send() logs an exact structured
 * payload line (to, template, variables) so the ACTIV host can QA formatting
 * without burning WhatsApp credits. Live MSG91 keys toggled via env change.
 */
@Injectable()
export class WhatsappChannelService {
  private readonly logger = new Logger(WhatsappChannelService.name);
  private readonly enabledRaw: string;
  private readonly templateId: string;

  constructor(config: ConfigService) {
    this.enabledRaw =
      config.get<string>("MSG91_WHATSAPP_ENABLED", "false") ?? "false";
    this.templateId =
      config.get<string>("MSG91_WHATSAPP_TEMPLATE_ID", "") ?? "";
  }

  get isDemoMode(): boolean {
    return this.enabledRaw !== "true" || !this.templateId;
  }

  async send(payload: {
    phoneE164: string;
    templateId?: string;
    variables?: Record<string, string>;
  }): Promise<{ delivered: boolean; demo: boolean }> {
    if (this.isDemoMode) {
      this.logger.log(
        `[WhatsApp-Demo] to=${payload.phoneE164} template=${this.templateId || payload.templateId || "unset"} vars=${JSON.stringify(payload.variables ?? {})}`,
      );
      return { delivered: false, demo: true };
    }
    this.logger.warn(
      `[WhatsApp] live channel configured but auth key not injected yet; demo fallback. to=${payload.phoneE164}`,
    );
    return { delivered: false, demo: true };
  }
}

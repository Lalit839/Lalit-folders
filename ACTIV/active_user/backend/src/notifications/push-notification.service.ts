import { Injectable, Logger } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { sign } from "node:crypto";
import { readFileSync } from "node:fs";

type ServiceAccount = {
  client_email: string;
  private_key: string;
  project_id: string;
};

type Device = { token: string };
type PushMessage = { title: string; body: string };

@Injectable()
export class PushNotificationService {
  private readonly logger = new Logger(PushNotificationService.name);
  private readonly serviceAccount: ServiceAccount | null = null;
  private accessToken = "";
  private tokenExpiresAt = 0;

  constructor(config: ConfigService) {
    const raw = config.get<string>("FCM_SERVICE_ACCOUNT");
    if (!raw) return;
    const jsonText = /\.json$/i.test(raw) ? readFileSync(raw, "utf8") : raw;
    try {
      const parsed = JSON.parse(jsonText) as ServiceAccount;
      if (!parsed.client_email || !parsed.private_key || !parsed.project_id)
        throw new Error("Missing client_email/private_key/project_id");
      this.serviceAccount = parsed;
      this.logger.log("FCM push notifications enabled");
    } catch (error) {
      this.logger.error(
        "Invalid FCM_SERVICE_ACCOUNT; push notifications disabled",
        error instanceof Error ? error.message : undefined,
      );
    }
  }

  get enabled(): boolean {
    return this.serviceAccount !== null;
  }

  async send(device: Device, message: PushMessage): Promise<void> {
    if (!this.serviceAccount) return;
    const token = await this.getAccessToken();
    const url = `https://fcm.googleapis.com/v1/projects/${this.serviceAccount.project_id}/messages:send`;
    const response = await fetch(url, {
      method: "POST",
      headers: {
        authorization: `Bearer ${token}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: device.token,
          notification: { title: message.title, body: message.body },
          android: { priority: "high" },
        },
      }),
      signal: AbortSignal.timeout(10_000),
    });
    if (!response.ok) {
      const body = await response.text().catch(() => "");
      throw new Error(
        `FCM error HTTP ${response.status}: ${body.slice(0, 200)}`,
      );
    }
  }

  private async getAccessToken(): Promise<string> {
    if (this.accessToken && Date.now() < this.tokenExpiresAt - 60_000)
      return this.accessToken;
    if (!this.serviceAccount) throw new Error("FCM is not configured");
    const now = Math.floor(Date.now() / 1000);
    const encode = (value: object): string =>
      Buffer.from(JSON.stringify(value)).toString("base64url");
    const header = { alg: "RS256", typ: "JWT" };
    const claims = {
      iss: this.serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    };
    const unsigned = `${encode(header)}.${encode(claims)}`;
    const signature = sign(
      "RSA-SHA256",
      Buffer.from(unsigned),
      this.serviceAccount.private_key,
    ).toString("base64url");
    const assertion = `${unsigned}.${signature}`;
    const response = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion,
      }),
      signal: AbortSignal.timeout(10_000),
    });
    const data = (await response.json().catch(() => null)) as {
      access_token?: string;
      expires_in?: number;
    } | null;
    if (!response.ok || !data?.access_token)
      throw new Error("FCM token exchange failed");
    this.accessToken = data.access_token;
    this.tokenExpiresAt = Date.now() + (data.expires_in ?? 3600) * 1000;
    return this.accessToken;
  }
}

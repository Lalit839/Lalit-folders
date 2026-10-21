import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Cron } from '@nestjs/schedule';

@Injectable()
export class KeepAliveService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(KeepAliveService.name);
  private readonly selfUrl: string | null = null;
  private readonly enabled: boolean;
  private inFlight = false;

  constructor(config: ConfigService) {
    this.enabled = config.get<string>('KEEPALIVE') === 'true';
    if (!this.enabled) return;
    this.selfUrl = this.normalize(config.get<string>('SELF_URL'));
    if (this.selfUrl) {
      this.logger.log(`Keep-alive enabled, pinging ${this.selfUrl}`);
    } else {
      this.logger.warn('KEEPALIVE=true but SELF_URL is not set; self-ping disabled');
    }
  }

  onModuleInit(): void {
    if (!this.enabled || !this.selfUrl) return;
    // Keep DB/Redis pools warm right after boot and schedule.
    void this.ping();
  }

  onModuleDestroy(): void {
    // no-op
  }

  @Cron('*/4 * * * *')
  private async scheduledPing(): Promise<void> {
    if (!this.enabled || !this.selfUrl) return;
    await this.ping();
  }

  private async ping(): Promise<void> {
    if (this.inFlight || !this.selfUrl) return;
    this.inFlight = true;
    try {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), 8_000);
      const response = await fetch(`${this.selfUrl}/api/v1/health`, {
        signal: controller.signal,
        headers: { 'x-keepalive': 'self' },
      });
      clearTimeout(timer);
      if (!response.ok) {
        this.logger.warn(`Keep-alive ping returned HTTP ${response.status}`);
      }
    } catch (error) {
      this.logger.warn(
        'Keep-alive ping failed',
        error instanceof Error ? error.message : 'Unknown error',
      );
    } finally {
      this.inFlight = false;
    }
  }

  private normalize(url: string | undefined): string | null {
    if (!url) return null;
    return url.replace(/\/+$/, '');
  }
}
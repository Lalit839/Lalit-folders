import { Controller, Get } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { RateLimitService } from '../security/rate-limit.service';

@Controller('health')
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly rateLimit: RateLimitService,
  ) {}

  @Get()
  async getHealth(): Promise<{
    status: string;
    service: string;
    timestamp: string;
    version: string;
    checks: { database: string; redis: string };
  }> {
    const [database, redis] = await Promise.all([
      this.checkDatabase(),
      this.rateLimit.ping(),
    ]);
    const unhealthy = database !== 'up' || !redis;
    return {
      status: unhealthy ? 'degraded' : 'ok',
      service: 'activ-backend',
      version: 'v1',
      timestamp: new Date().toISOString(),
      checks: { database, redis: redis ? 'up' : 'down' },
    };
  }

  private async checkDatabase(): Promise<'up' | 'down'> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return 'up';
    } catch {
      return 'down';
    }
  }
}
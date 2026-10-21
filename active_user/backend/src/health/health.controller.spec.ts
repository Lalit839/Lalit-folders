import { HealthController } from './health.controller';

describe('HealthController', () => {
  it('returns healthy when the database and redis respond', async () => {
    const controller = new HealthController(
      { $queryRaw: jest.fn().mockResolvedValue([{ ok: 1 }]) } as never,
      { ping: jest.fn().mockResolvedValue(true) } as never,
    );
    const result = await controller.getHealth();
    expect(result.status).toBe('ok');
    expect(result.service).toBe('activ-backend');
    expect(result.checks.database).toBe('up');
    expect(result.checks.redis).toBe('up');
  });

  it('reports degraded when the database fails', async () => {
    const controller = new HealthController(
      { $queryRaw: jest.fn().mockRejectedValue(new Error('offline')) } as never,
      { ping: jest.fn().mockResolvedValue(true) } as never,
    );
    const result = await controller.getHealth();
    expect(result.status).toBe('degraded');
    expect(result.checks.database).toBe('down');
  });

  it('reports degraded when redis is unavailable', async () => {
    const controller = new HealthController(
      { $queryRaw: jest.fn().mockResolvedValue([{ ok: 1 }]) } as never,
      { ping: jest.fn().mockResolvedValue(false) } as never,
    );
    const result = await controller.getHealth();
    expect(result.status).toBe('degraded');
    expect(result.checks.redis).toBe('down');
  });
});
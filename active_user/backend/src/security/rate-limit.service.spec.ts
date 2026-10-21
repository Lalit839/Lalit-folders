import { HttpException } from '@nestjs/common';
import { RateLimitService } from './rate-limit.service';

const mockIncr = jest.fn();
const mockExpire = jest.fn();
const mockQuit = jest.fn();

jest.mock('ioredis', () => jest.fn().mockImplementation(() => ({ incr: mockIncr, expire: mockExpire, quit: mockQuit })));

describe('RateLimitService', () => {
  beforeEach(() => jest.clearAllMocks());

  it('allows requests within the configured window', async () => {
    mockIncr.mockResolvedValue(1);
    const service = new RateLimitService({ get: jest.fn().mockReturnValue('redis://localhost:6379') } as never);
    await expect(service.assertAllowed('otp:phone', 3, 900)).resolves.toBeUndefined();
    expect(mockExpire).toHaveBeenCalledWith('otp:phone', 900);
    await service.onModuleDestroy();
  });

  it('returns HTTP 429 after the limit is exceeded', async () => {
    mockIncr.mockResolvedValue(4);
    const service = new RateLimitService({ get: jest.fn().mockReturnValue('redis://localhost:6379') } as never);
    await expect(service.assertAllowed('otp:phone', 3, 900)).rejects.toBeInstanceOf(HttpException);
    await service.onModuleDestroy();
  });
});

import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RolesGuard } from './roles.guard';

const context = (roles: string[]) => ({
  getHandler: jest.fn(),
  getClass: jest.fn(),
  switchToHttp: () => ({ getRequest: () => ({ user: { roles } }) }),
}) as unknown as ExecutionContext;

describe('RolesGuard', () => {
  it('allows a required role', () => {
    const reflector = { getAllAndOverride: jest.fn().mockReturnValue(['PARTNER_ADMIN']) } as unknown as Reflector;
    expect(new RolesGuard(reflector).canActivate(context(['USER', 'PARTNER_ADMIN']))).toBe(true);
  });

  it('rejects a user without the required role', () => {
    const reflector = { getAllAndOverride: jest.fn().mockReturnValue(['PARTNER_ADMIN']) } as unknown as Reflector;
    expect(() => new RolesGuard(reflector).canActivate(context(['USER']))).toThrow(ForbiddenException);
  });
});

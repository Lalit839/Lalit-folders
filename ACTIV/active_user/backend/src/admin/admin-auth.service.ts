import { Injectable, UnauthorizedException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { JwtService } from "@nestjs/jwt";
import {
  randomBytes,
  randomUUID,
  scryptSync,
  timingSafeEqual,
} from "node:crypto";
import { PrismaService } from "../database/prisma.service";

@Injectable()
export class AdminAuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  async login(email: string, password: string) {
    const normalized = email.trim().toLowerCase();
    const user = await this.prisma.user.findFirst({
      where: { email: normalized, isAdmin: true },
      select: {
        id: true,
        email: true,
        passwordHash: true,
        status: true,
        authzVersion: true,
      },
    });
    if (!user || !user.passwordHash || user.status !== "ACTIVE")
      throw new UnauthorizedException("Invalid credentials");
    if (!this.matches(user.passwordHash, password))
      throw new UnauthorizedException("Invalid credentials");

    const sessionId = randomUUID();
    const refreshToken = randomBytes(48).toString("base64url");
    await this.prisma.session.create({
      data: {
        id: sessionId,
        userId: user.id,
        tokenHash: this.hashScrypt(refreshToken),
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      },
    });
    const accessToken = await this.jwt.signAsync({
      sub: user.id,
      sessionId,
      authzVersion: user.authzVersion,
      roles: ["USER", "ADMIN"],
    });
    return {
      accessToken,
      refreshToken,
      user: { id: user.id, email: user.email, isAdmin: true },
    };
  }

  hashPassword(value: string): string {
    return this.hashScrypt(value);
  }

  private hashScrypt(value: string): string {
    return scryptSync(
      value,
      this.config.getOrThrow<string>("JWT_REFRESH_SECRET").slice(0, 16),
      32,
    ).toString("hex");
  }

  private matches(expected: string, value: string): boolean {
    const actual = Buffer.from(this.hashScrypt(value), "hex");
    const stored = Buffer.from(expected, "hex");
    return actual.length === stored.length && timingSafeEqual(actual, stored);
  }
}

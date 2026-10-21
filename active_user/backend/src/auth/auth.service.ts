import {
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { JwtService } from "@nestjs/jwt";
import { Prisma } from "@prisma/client";
import { RateLimitService } from "../security/rate-limit.service";
import {
  randomBytes,
  randomInt,
  randomUUID,
  scryptSync,
  timingSafeEqual,
} from "node:crypto";
import { PrismaService } from "../database/prisma.service";
import { Cron } from "@nestjs/schedule";
import { timePerfStage, timeSyncPerfStage } from "../common/perf-timing";

const OTP_TTL_MS = 5 * 60 * 1000;
const MAX_OTP_ATTEMPTS = 5;

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly rateLimit: RateLimitService,
  ) {}

  async requestOtp(
    phone: string,
    ip: string,
  ): Promise<{ requestId: string; expiresAt: string }> {
    await this.rateLimit.assertAllowed(
      `activ:otp:request:phone:${phone}`,
      3,
      900,
    );
    await this.rateLimit.assertAllowed(`activ:otp:request:ip:${ip}`, 10, 900);

    const demoMode = process.env.DEMO_OTP === "true";
    const code = demoMode
      ? "0000"
      : randomInt(0, 10000).toString().padStart(4, "0");

    if (!demoMode) await this.sendOtp(phone, code);

    const challenge = await this.prisma.otpChallenge.create({
      data: {
        phoneE164: phone,
        codeHash: this.hash(code),
        expiresAt: new Date(Date.now() + OTP_TTL_MS),
      },
      select: { id: true, expiresAt: true },
    });

    return {
      requestId: challenge.id,
      expiresAt: challenge.expiresAt.toISOString(),
    };
  }

  async verifyOtp(
    phone: string,
    code: string,
    ip: string,
  ): Promise<{ accessToken: string; refreshToken: string }> {
    await this.rateLimit.assertAllowed(
      `activ:otp:verify:phone:${phone}`,
      10,
      900,
    );
    await this.rateLimit.assertAllowed(`activ:otp:verify:ip:${ip}`, 30, 900);
    const challenge = await this.prisma.otpChallenge.findFirst({
      where: {
        phoneE164: phone,
        consumedAt: null,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: "desc" },
    });
    if (!challenge || challenge.attempts >= MAX_OTP_ATTEMPTS)
      throw new UnauthorizedException("Invalid or expired OTP");

    const valid = this.matches(challenge.codeHash, code);
    if (valid) {
      const consumed = await this.prisma.otpChallenge.updateMany({
        where: {
          id: challenge.id,
          consumedAt: null,
          expiresAt: { gt: new Date() },
          attempts: { lt: MAX_OTP_ATTEMPTS },
        },
        data: { consumedAt: new Date() },
      });
      if (!consumed.count)
        throw new UnauthorizedException("Invalid or expired OTP");
    } else {
      await this.prisma.otpChallenge.updateMany({
        where: {
          id: challenge.id,
          consumedAt: null,
          attempts: { lt: MAX_OTP_ATTEMPTS },
        },
        data: { attempts: { increment: 1 } },
      });
      throw new UnauthorizedException("Invalid or expired OTP");
    }

    const user = await this.prisma.user.upsert({
      where: { phoneE164: phone },
      create: { phoneE164: phone },
      update: {},
      select: {
        id: true,
        authzVersion: true,
        isAdmin: true,
        // Partner memberships are joined at login too so the freshly issued
        // access token carries the same roles as a refreshed one (Step 7).
        partnerUsers: { select: { role: true } },
      },
    });
    const sessionId = randomUUID();
    const refreshToken = randomBytes(48).toString("base64url");
    await this.prisma.session.create({
      data: {
        id: sessionId,
        userId: user.id,
        tokenHash: this.hash(refreshToken),
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      },
    });
    const accessToken = await this.jwt.signAsync({
      sub: user.id,
      sessionId,
      authzVersion: user.authzVersion,
      roles: [
        "USER",
        ...(user.isAdmin ? ["ADMIN"] : []),
        ...(user.partnerUsers ?? []).map((membership) => membership.role),
      ],
    });
    return { accessToken, refreshToken };
  }

  async refresh(
    refreshToken: string,
  ): Promise<{ accessToken: string; refreshToken: string }> {
    return timePerfStage("auth.refresh.total", async () => {
      const tokenHash = timeSyncPerfStage("auth.refresh.hash", () =>
        this.hash(refreshToken),
      );
      const session = await timePerfStage("auth.refresh.sessionDb", () =>
        this.prisma.session.findUnique({
          where: { tokenHash },
          include: {
            user: {
              select: {
                authzVersion: true,
                status: true,
                isAdmin: true,
                partnerUsers: { select: { role: true } },
              },
            },
          },
        }),
      );
      if (
        !session ||
        session.revokedAt ||
        session.expiresAt <= new Date() ||
        session.user.status !== "ACTIVE"
      )
        throw new UnauthorizedException("Refresh session is no longer valid");
      const nextRefreshToken = randomBytes(48).toString("base64url");
      const nextSessionId = randomUUID();
      const roles = [
        "USER",
        ...(session.user.isAdmin ? ["ADMIN"] : []),
        ...session.user.partnerUsers.map((membership) => membership.role),
      ];
      await timePerfStage("auth.refresh.transaction", () =>
        this.prisma.$transaction(async (tx) => {
          const revoked = await tx.session.updateMany({
            where: {
              id: session.id,
              revokedAt: null,
              expiresAt: { gt: new Date() },
            },
            data: { revokedAt: new Date() },
          });
          if (revoked.count !== 1)
            throw new UnauthorizedException(
              "Refresh session is no longer valid",
            );
          await tx.session.create({
            data: {
              id: nextSessionId,
              userId: session.userId,
              tokenHash: this.hash(nextRefreshToken),
              expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
            },
          });
        }),
      );
      const accessToken = await timePerfStage("auth.refresh.jwtSign", () =>
        this.jwt.signAsync({
          sub: session.userId,
          sessionId: nextSessionId,
          authzVersion: session.user.authzVersion,
          roles,
        }),
      );
      return { accessToken, refreshToken: nextRefreshToken };
    });
  }

  async getProfile(userId: string) {
    const user = await timePerfStage("me.userDb", () =>
      this.prisma.user.findUniqueOrThrow({
        where: { id: userId },
        select: {
          id: true,
          phoneE164: true,
          name: true,
          email: true,
          profilePhoto: true,
          preferences: true,
          status: true,
          createdAt: true,
        },
      }),
    );
    return timeSyncPerfStage("me.serialize", () => user);
  }

  updateProfile(
    userId: string,
    input: {
      name?: string;
      email?: string;
      profilePhoto?: string;
      preferences?: Prisma.InputJsonValue;
    },
  ) {
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(input.name !== undefined ? { name: input.name.trim() } : {}),
        ...(input.email !== undefined
          ? { email: input.email.trim().toLowerCase() || null }
          : {}),
        ...(input.profilePhoto !== undefined
          ? { profilePhoto: input.profilePhoto || null }
          : {}),
        ...(input.preferences !== undefined
          ? { preferences: input.preferences }
          : {}),
      },
      select: {
        id: true,
        phoneE164: true,
        name: true,
        email: true,
        profilePhoto: true,
        preferences: true,
        status: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  async logout(sessionId: string): Promise<{ revoked: true }> {
    await this.prisma.session.updateMany({
      where: { id: sessionId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    return { revoked: true };
  }

  async requestDeletion(userId: string) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { deletionRequestedAt: new Date() },
      select: { id: true, deletionRequestedAt: true },
    });
    return { status: "DELETION_REQUESTED", ...user };
  }

  private hash(value: string): string {
    return scryptSync(
      value,
      this.config.getOrThrow<string>("JWT_REFRESH_SECRET").slice(0, 16),
      32,
    ).toString("hex");
  }

  private matches(expected: string, value: string): boolean {
    const actual = Buffer.from(this.hash(value), "hex");
    const stored = Buffer.from(expected, "hex");
    return actual.length === stored.length && timingSafeEqual(actual, stored);
  }

  private async sendOtp(phone: string, code: string): Promise<void> {
    const authKey = this.config.get<string>("OTP_PROVIDER_API_KEY");
    const templateId = this.config.get<string>("OTP_PROVIDER_TEMPLATE_ID");
    if (!authKey || !templateId)
      throw new ServiceUnavailableException("OTP delivery is not configured");

    try {
      const controller = this.config.get<string>("OTP_PROVIDER_SIM_MODE");
      const response = await fetch("https://control.msg91.com/api/v5/otp", {
        method: "POST",
        headers: {
          authkey: authKey,
          "content-type": "application/json",
        },
        body: JSON.stringify({
          template_id: templateId,
          mobile: phone.replace(/^\+/, ""),
          otp: code,
          otp_expiry: 5,
          ...(controller && { country: "" }),
        }),
        signal: AbortSignal.timeout(10_000),
      });
      const body = (await response.json().catch(() => null)) as {
        type?: string;
        message?: string;
      } | null;
      if (!response.ok)
        throw new Error(
          `MSG91 returned HTTP ${response.status}: ${body?.message ?? ""}`,
        );
    } catch (error) {
      if (error instanceof Error && error.name === "TimeoutError")
        throw new ServiceUnavailableException("OTP delivery timed out");
      throw new ServiceUnavailableException("OTP delivery failed");
    }
  }

  @Cron("0 3 * * *")
  async anonymizeExpiredAccounts(): Promise<void> {
    const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const users = await this.prisma.user.findMany({
      where: {
        deletionRequestedAt: { lte: cutoff },
        status: { not: "DELETED" },
      },
      select: { id: true },
      take: 100,
    });
    for (const user of users) {
      await this.prisma.$transaction(async (tx) => {
        const updated = await tx.user.updateMany({
          where: {
            id: user.id,
            deletionRequestedAt: { lte: cutoff },
            status: { not: "DELETED" },
          },
          data: {
            phoneE164: `deleted:${user.id}`,
            name: null,
            preferences: {},
            status: "DELETED",
          },
        });
        if (updated.count) {
          await tx.session.updateMany({
            where: { userId: user.id, revokedAt: null },
            data: { revokedAt: new Date() },
          });
          await tx.auditEvent.create({
            data: {
              actorId: null,
              action: "ACCOUNT_ANONYMIZED",
              entityType: "USER",
              entityId: user.id,
              afterJson: { reason: "ACCOUNT_DELETION" },
            },
          });
        }
      });
    }
  }
}

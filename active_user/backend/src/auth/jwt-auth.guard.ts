import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { PrismaService } from "../database/prisma.service";
import { AuthenticatedUser } from "./current-user.decorator";
import { timePerfStage } from "../common/perf-timing";

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwt: JwtService,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<{
      headers: Record<string, string | undefined>;
      originalUrl?: string;
      url?: string;
      user?: AuthenticatedUser;
    }>();
    const path = request.originalUrl ?? request.url ?? "";
    const isAdminRequest = path.includes("/admin/");
    const prefix = this.perfPrefixForPath(path);
    return timePerfStage(`${prefix}.auth`, async () => {
      const token = request.headers.authorization?.startsWith("Bearer ")
        ? request.headers.authorization.slice(7)
        : undefined;
      if (!token) throw new UnauthorizedException("Authentication required");

      try {
        const payload = await timePerfStage(`${prefix}.jwtVerify`, () =>
          this.jwt.verifyAsync<{
            sub: string;
            sessionId: string;
            authzVersion: number;
            roles?: string[];
          }>(token, {
            issuer: "activ-api",
            audience: "activ-mobile",
          }),
        );
        const session = await timePerfStage(
          isAdminRequest ? "admin.sessionDb" : "auth.sessionDb",
          () =>
            this.prisma.session.findUnique({
              where: { id: payload.sessionId },
              select: {
                revokedAt: true,
                expiresAt: true,
                user: { select: { status: true, authzVersion: true } },
              },
            }),
        );
        if (
          !session ||
          session.revokedAt ||
          session.expiresAt <= new Date() ||
          session.user.status !== "ACTIVE" ||
          session.user.authzVersion !== payload.authzVersion
        ) {
          throw new UnauthorizedException("Session is no longer valid");
        }
        request.user = {
          id: payload.sub,
          sessionId: payload.sessionId,
          roles: payload.roles ?? [],
        };
        return true;
      } catch (error) {
        if (error instanceof UnauthorizedException) throw error;
        throw new UnauthorizedException("Invalid access token");
      }
    });
  }

  private perfPrefixForPath(path: string): string {
    if (path.includes("/admin/")) return "admin";
    if (path.includes("/payment") || path.includes("/payments/"))
      return "payment";
    if (path.includes("/bookings") || path.includes("/booking-attempts"))
      return "bookings";
    if (path.endsWith("/me") || path.includes("/me?")) return "me";
    return "auth";
  }
}

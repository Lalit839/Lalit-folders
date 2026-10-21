import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { Observable, map } from "rxjs";
import { Request } from "express";
import { SKIP_RESPONSE_ENVELOPE } from "./skip-response-envelope.decorator";
import { timeSyncPerfStage } from "./perf-timing";

@Injectable()
export class ApiEnvelopeInterceptor implements NestInterceptor {
  constructor(private readonly reflector: Reflector) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context
      .switchToHttp()
      .getRequest<Request & { requestId?: string }>();
    const skip = this.reflector.getAllAndOverride<boolean>(
      SKIP_RESPONSE_ENVELOPE,
      [context.getHandler(), context.getClass()],
    );
    if (skip) return next.handle();
    return next.handle().pipe(
      map((data: unknown) =>
        timeSyncPerfStage("response.envelope", () => ({
          data,
          requestId: request.requestId,
        })),
      ),
    );
  }
}

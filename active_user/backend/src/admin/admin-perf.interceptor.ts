import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from "@nestjs/common";
import { Observable } from "rxjs";
import { finalize } from "rxjs/operators";
import { recordPerfStage } from "../common/perf-timing";

@Injectable()
export class AdminPerfInterceptor implements NestInterceptor {
  intercept(
    _context: ExecutionContext,
    next: CallHandler,
  ): Observable<unknown> {
    const startedAt = process.hrtime.bigint();
    return next.handle().pipe(
      finalize(() => {
        const durationMs =
          Number(process.hrtime.bigint() - startedAt) / 1_000_000;
        recordPerfStage("admin.endpointDb", durationMs);
      }),
    );
  }
}

import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from "@nestjs/common";
import { Request, Response } from "express";

@Catch()
export class ApiExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const context = host.switchToHttp();
    const request = context.getRequest<Request & { requestId?: string }>();
    const response = context.getResponse<Response>();
    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;
    const exceptionResponse =
      exception instanceof HttpException ? exception.getResponse() : undefined;
    const message = this.messageFor(exceptionResponse, status);
    const details =
      typeof exceptionResponse === "object" && exceptionResponse !== null
        ? exceptionResponse
        : {};
    if (!(exception instanceof HttpException)) {
      console.error(
        exception instanceof Error
          ? (exception.stack ?? exception.message)
          : exception,
      );
    }
    response
      .status(status)
      .json({
        error: { code: this.codeFor(status), message, details },
        requestId: request.requestId,
      });
  }

  private messageFor(exceptionResponse: unknown, status: number): string {
    if (typeof exceptionResponse === "string" && exceptionResponse.trim()) {
      return exceptionResponse;
    }
    if (exceptionResponse !== null && typeof exceptionResponse === "object") {
      const body = exceptionResponse as Record<string, unknown>;
      if (typeof body.message === "string" && body.message.trim()) {
        return body.message;
      }
      if (Array.isArray(body.message)) {
        const joined = body.message
          .filter(
            (part): part is string =>
              typeof part === "string" && part.trim().length > 0,
          )
          .join("; ");
        if (joined) return joined;
      }
      if (typeof body.error === "string" && body.error.trim()) {
        return body.error;
      }
    }
    return status === HttpStatus.INTERNAL_SERVER_ERROR
      ? "Unexpected server error"
      : "Request failed";
  }

  private codeFor(status: number): string {
    const codes: Record<number, string> = {
      400: "INVALID_REQUEST",
      401: "UNAUTHORIZED",
      403: "FORBIDDEN",
      404: "NOT_FOUND",
      409: "CONFLICT",
      422: "BUSINESS_RULE_FAILED",
      429: "RATE_LIMITED",
    };
    return codes[status] ?? "INTERNAL_SERVER_ERROR";
  }
}

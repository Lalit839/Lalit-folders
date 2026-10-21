import { RequestMethod, ValidationPipe } from "@nestjs/common";
import { NestFactory } from "@nestjs/core";
import { json, NextFunction, Request, Response } from "express";
import helmet from "helmet";
import { randomUUID } from "node:crypto";
import { AppModule } from "./app.module";
import { ApiExceptionFilter } from "./common/api-exception.filter";
import { currentPerfSnapshot, runWithPerfContext } from "./common/perf-timing";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule, { bodyParser: false });
  app.enableShutdownHooks();
  app.use(
    json({
      limit: "1mb",
      verify: (request, _response, buffer) => {
        (request as Request & { rawBody?: Buffer }).rawBody =
          Buffer.from(buffer);
      },
    }),
  );

  app.setGlobalPrefix("api/v1", {
    exclude: [
      { path: "api", method: RequestMethod.ALL },
      { path: "api/(.*)", method: RequestMethod.ALL },
    ],
  });
  if (process.env.NODE_ENV !== "production") {
    const swaggerConfig = new DocumentBuilder()
      .setTitle("ACTIV API")
      .setDescription("ACTIV marketplace API")
      .setVersion("1.0")
      .addBearerAuth()
      .build();
    SwaggerModule.setup(
      "api/docs",
      app,
      SwaggerModule.createDocument(app, swaggerConfig),
    );
  }
  app.use(helmet());
  const origins = (process.env.CORS_ORIGINS ?? "")
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean);
  if (process.env.NODE_ENV === "production" && origins.length === 0)
    throw new Error("CORS_ORIGINS must be configured in production");
  const isWildcard = origins.length === 1 && origins[0] === "*";
  app.enableCors({
    origin:
      process.env.NODE_ENV === "production"
        ? (
            origin: string | undefined,
            callback: (error: Error | null, allow?: boolean) => void,
          ) => {
            if (isWildcard) return callback(null, true);
            if (!origin || origins.includes(origin) || isLoopbackOrigin(origin))
              return callback(null, true);
            return callback(null, false);
          }
        : true,
    credentials: !isWildcard,
  });
  app.use(
    (
      request: Request & { requestId?: string },
      response: Response,
      next: NextFunction,
    ) => {
      const headerRequestId = request.headers["x-request-id"];
      const requestId =
        typeof headerRequestId === "string" ? headerRequestId : randomUUID();
      request.requestId = requestId;
      response.setHeader("x-request-id", requestId);
      runWithPerfContext(
        { requestId, method: request.method, path: request.originalUrl },
        () => {
          response.on("finish", () => {
            const perf = currentPerfSnapshot();
            console.log(
              JSON.stringify({
                timestamp: new Date().toISOString(),
                level: "info",
                type: "request",
                requestId,
                method: request.method,
                path: request.originalUrl,
                statusCode: response.statusCode,
                durationMs: perf?.totalMs ?? 0,
                perfStages: perf?.stages ?? [],
              }),
            );
          });
          next();
        },
      );
    },
  );
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.useGlobalFilters(new ApiExceptionFilter());

  await app.listen(process.env.PORT ?? 3000);
}

function isLoopbackOrigin(origin: string): boolean {
  try {
    const { hostname, protocol } = new URL(origin);
    return (
      (protocol === "http:" || protocol === "https:") &&
      (hostname === "localhost" ||
        hostname === "127.0.0.1" ||
        hostname === "[::1]")
    );
  } catch {
    return false;
  }
}

void bootstrap();

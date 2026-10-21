import { PrismaClient } from "@prisma/client";

type SanitizedDbConfig = {
  source: string;
  host: string | null;
  port: string | null;
  database: string | null;
  connectionLimit: string | null;
  poolTimeout: string | null;
  pgbouncer: string | null;
  sslmode: string | null;
  poolerMode: string;
};

const prisma = new PrismaClient();

function sanitizeDatabaseUrl(
  value: string | undefined,
  source: string,
): SanitizedDbConfig {
  if (!value) {
    return {
      source,
      host: null,
      port: null,
      database: null,
      connectionLimit: null,
      poolTimeout: null,
      pgbouncer: null,
      sslmode: null,
      poolerMode: "not configured",
    };
  }

  try {
    const url = new URL(value);
    const host = url.hostname || null;
    const port = url.port || null;
    return {
      source,
      host,
      port,
      database: url.pathname ? url.pathname.replace(/^\//, "") : null,
      connectionLimit: url.searchParams.get("connection_limit"),
      poolTimeout: url.searchParams.get("pool_timeout"),
      pgbouncer: url.searchParams.get("pgbouncer"),
      sslmode: url.searchParams.get("sslmode"),
      poolerMode: inferPoolerMode(host, port),
    };
  } catch {
    return {
      source,
      host: "invalid url",
      port: null,
      database: null,
      connectionLimit: null,
      poolTimeout: null,
      pgbouncer: null,
      sslmode: null,
      poolerMode: "unknown",
    };
  }
}

function inferPoolerMode(host: string | null, port: string | null): string {
  if (!host) return "unknown";
  if (host.includes("pooler.supabase.com") && port === "6543") {
    return "supabase transaction pooler";
  }
  if (host.includes("pooler.supabase.com")) {
    return "supabase pooler";
  }
  if (host.startsWith("db.") && host.endsWith(".supabase.co")) {
    return "supabase direct";
  }
  return "unknown";
}

function elapsedMs(startedAt: bigint): number {
  return (
    Math.round(
      (Number(process.hrtime.bigint() - startedAt) / 1_000_000) * 100,
    ) / 100
  );
}

async function timedSelect(
  label: string,
): Promise<{ label: string; durationMs: number }> {
  const startedAt = process.hrtime.bigint();
  await prisma.$queryRaw`SELECT 1`;
  return { label, durationMs: elapsedMs(startedAt) };
}

function summarize(values: Array<{ durationMs: number }>) {
  const sorted = values.map((item) => item.durationMs).sort((a, b) => a - b);
  const sum = sorted.reduce((total, value) => total + value, 0);
  return {
    minMs: sorted[0] ?? null,
    maxMs: sorted[sorted.length - 1] ?? null,
    avgMs: sorted.length ? Math.round((sum / sorted.length) * 100) / 100 : null,
  };
}

async function main() {
  console.log(
    JSON.stringify(
      {
        dbConfig: [
          sanitizeDatabaseUrl(process.env.DATABASE_URL, "DATABASE_URL"),
          sanitizeDatabaseUrl(process.env.DIRECT_URL, "DIRECT_URL"),
        ],
      },
      null,
      2,
    ),
  );

  const connectStartedAt = process.hrtime.bigint();
  await prisma.$connect();
  console.log(
    JSON.stringify({
      stage: "connect",
      durationMs: elapsedMs(connectStartedAt),
    }),
  );

  const first = await timedSelect("first");
  console.log(JSON.stringify(first));

  const sequential = [];
  for (let index = 0; index < 10; index += 1) {
    sequential.push(await timedSelect(`sequential.${index + 1}`));
  }
  console.log(
    JSON.stringify({
      stage: "sequential",
      runs: sequential,
      summary: summarize(sequential),
    }),
  );

  const concurrent = await Promise.all(
    Array.from({ length: 10 }, (_value, index) =>
      timedSelect(`concurrent.${index + 1}`),
    ),
  );
  console.log(
    JSON.stringify({
      stage: "concurrent",
      runs: concurrent,
      summary: summarize(concurrent),
    }),
  );
}

main()
  .catch((error: unknown) => {
    const message = error instanceof Error ? error.message : "Unknown error";
    console.error(JSON.stringify({ error: message }));
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

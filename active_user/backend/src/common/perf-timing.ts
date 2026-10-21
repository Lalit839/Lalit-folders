import { AsyncLocalStorage } from "node:async_hooks";

type PerfStage = {
  name: string;
  durationMs: number;
  metadata?: Record<string, unknown>;
};

type PerfContext = {
  requestId: string;
  method: string;
  path: string;
  startedAt: bigint;
  stages: PerfStage[];
};

const storage = new AsyncLocalStorage<PerfContext>();

function elapsedMs(startedAt: bigint): number {
  return Number(process.hrtime.bigint() - startedAt) / 1_000_000;
}

export function runWithPerfContext<T>(
  context: Omit<PerfContext, "startedAt" | "stages">,
  callback: () => T,
): T {
  return storage.run(
    {
      ...context,
      startedAt: process.hrtime.bigint(),
      stages: [],
    },
    callback,
  );
}

export function recordPerfStage(
  name: string,
  durationMs: number,
  metadata?: Record<string, unknown>,
): void {
  const context = storage.getStore();
  if (!context) return;
  context.stages.push({
    name,
    durationMs: Math.round(durationMs * 100) / 100,
    ...(metadata ? { metadata } : {}),
  });
}

export async function timePerfStage<T>(
  name: string,
  callback: () => Promise<T>,
  metadata?: Record<string, unknown>,
): Promise<T> {
  const startedAt = process.hrtime.bigint();
  try {
    return await callback();
  } finally {
    recordPerfStage(name, elapsedMs(startedAt), metadata);
  }
}

export function timeSyncPerfStage<T>(
  name: string,
  callback: () => T,
  metadata?: Record<string, unknown>,
): T {
  const startedAt = process.hrtime.bigint();
  try {
    return callback();
  } finally {
    recordPerfStage(name, elapsedMs(startedAt), metadata);
  }
}

export function currentPerfSnapshot(): {
  totalMs: number;
  stages: PerfStage[];
} | null {
  const context = storage.getStore();
  if (!context) return null;
  return {
    totalMs: Math.round(elapsedMs(context.startedAt) * 100) / 100,
    stages: [...context.stages],
  };
}

import { OutboxService } from "./outbox.service";

const disabledPush = { enabled: false } as never;

describe("OutboxService", () => {
  it("moves unknown event types to dead-letter status", async () => {
    const update = jest.fn().mockResolvedValue({});
    const prisma = {
      outboxEvent: {
        findMany: jest
          .fn()
          .mockResolvedValue([{ id: "event-1", type: "UNKNOWN", attempts: 0 }]),
        update,
      },
    };
    await new OutboxService(prisma as never, disabledPush).dispatchPending();
    expect(update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: "event-1" },
        data: expect.objectContaining({
          status: "FAILED",
          attempts: { increment: 1 },
        }),
      }),
    );
  });

  it("creates a notification in the same transaction for a booking event", async () => {
    const tx = {
      outboxEvent: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
      notification: {
        create: jest.fn().mockResolvedValue({ id: "notification-1" }),
      },
    };
    const prisma = {
      outboxEvent: {
        findMany: jest
          .fn()
          .mockResolvedValue([
            {
              id: "event-1",
              type: "BOOKING_CONFIRMED",
              attempts: 0,
              payload: { bookingId: "booking-1", userId: "user-1" },
            },
          ]),
      },
      $transaction: jest.fn(
        async (callback: (value: typeof tx) => Promise<void>) => callback(tx),
      ),
    };
    await new OutboxService(prisma as never, disabledPush).dispatchPending();
    expect(tx.notification.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          userId: "user-1",
          bookingId: "booking-1",
          type: "BOOKING_CONFIRMED",
          status: "SENT",
          sentAt: expect.any(Date),
        }),
      }),
    );
  });
});

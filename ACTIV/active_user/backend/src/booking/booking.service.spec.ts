import { BookingService } from "./booking.service";

describe("BookingService", () => {
  it("subtracts active held quantity from slot availability", async () => {
    const prisma = {
      slot: {
        findUnique: jest
          .fn()
          .mockResolvedValue({
            id: "slot",
            capacity: 10,
            bookedQuantity: 3,
            startsAt: new Date(Date.now() + 60_000),
            endsAt: new Date(Date.now() + 3_600_000),
            status: "AVAILABLE",
            pricePaise: BigInt(10000),
          }),
      },
      bookingAttempt: {
        aggregate: jest.fn().mockResolvedValue({ _sum: { quantity: 2 } }),
      },
    };
    const service = new BookingService(prisma as never);
    const result = await service.getAvailability("slot");
    expect(result.availableQuantity).toBe(5);
    expect(result.pricePaise).toBe("10000");
  });
});

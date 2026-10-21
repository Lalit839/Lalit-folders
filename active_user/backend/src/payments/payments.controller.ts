import {
  Body,
  Controller,
  Get,
  Headers,
  Param,
  Post,
  RawBodyRequest,
  Req,
  UseGuards,
} from "@nestjs/common";
import { Request } from "express";
import { AuthenticatedUser, CurrentUser } from "../auth/current-user.decorator";
import { JwtAuthGuard } from "../auth/jwt-auth.guard";
import { PaymentsService } from "./payments.service";

@Controller()
export class PaymentsController {
  constructor(private readonly payments: PaymentsService) {}

  @Post("booking-attempts/:attemptId/payment-order")
  @UseGuards(JwtAuthGuard)
  createOrder(
    @CurrentUser() user: AuthenticatedUser,
    @Param("attemptId") attemptId: string,
    @Headers("idempotency-key") key: string,
  ) {
    return this.payments.createOrder(user.id, attemptId, key);
  }

  @Get("payments/:paymentId")
  @UseGuards(JwtAuthGuard)
  getStatus(
    @CurrentUser() user: AuthenticatedUser,
    @Param("paymentId") paymentId: string,
  ) {
    return this.payments.getStatus(user.id, paymentId);
  }

  @Post("payments/razorpay/confirm")
  @UseGuards(JwtAuthGuard)
  confirmRazorpayPayment(
    @CurrentUser() user: AuthenticatedUser,
    @Body()
    body: {
      paymentId?: string;
      razorpayPaymentId?: string;
      razorpayOrderId?: string;
      razorpaySignature?: string;
    },
  ) {
    return this.payments.confirmClientPayment(
      user.id,
      body.paymentId ?? "",
      body.razorpayPaymentId ?? "",
      body.razorpayOrderId ?? "",
      body.razorpaySignature ?? "",
    );
  }

  @Post("payments/webhook/razorpay")
  handleWebhook(
    @Headers("x-razorpay-signature") signature: string,
    @Req() request: RawBodyRequest<Request>,
  ) {
    return this.payments.handleWebhook(
      signature,
      request.rawBody ?? Buffer.from(""),
    );
  }
}

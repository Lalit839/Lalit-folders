import { Body, Controller, Post } from "@nestjs/common";
import { IsEmail, IsString, MinLength, MaxLength } from "class-validator";
import { AdminAuthService } from "./admin-auth.service";

class AdminLoginDto {
  @IsEmail()
  @MaxLength(320)
  email!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;
}

@Controller("admin/auth")
export class AdminAuthController {
  constructor(private readonly auth: AdminAuthService) {}

  @Post("login")
  login(@Body() dto: AdminLoginDto) {
    return this.auth.login(dto.email, dto.password);
  }
}

import {
  Body,
  Controller,
  Get,
  HttpCode,
  Patch,
  Post,
  Request,
  UseGuards,
  ValidationPipe,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { UnifiedRegisterDto } from './dto/unified-register.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { Verify2faDto } from './dto/verify-2fa.dto';
import { Login2faDto } from './dto/login-2fa.dto';

@Controller('')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  register(@Body(ValidationPipe) registerDto: UnifiedRegisterDto) {
    return this.auth.register(registerDto);
  }

  @HttpCode(200)
  @Post('login')
  login(@Body(ValidationPipe) dto: LoginDto) {
    return this.auth.login(dto);
  }

  @UseGuards(AuthGuard('jwt'))
  @Post('logout')
  logout(@Request() req) {
    return this.auth.logout(req.user.userId);
  }

  @UseGuards(AuthGuard('jwt-refresh'))
  @Get('refresh')
  refreshToken(@Request() req) {
    const userId = req.user.userId;
    const refreshToken = req.user.refreshToken;
    return this.auth.refreshToken(userId, refreshToken);
  }

  @Patch('change-password')
  @UseGuards(AuthGuard('jwt'))
  changePassword(@Request() req, @Body() changePasswordDto: ChangePasswordDto) {
    const userId = req.user.userId;
    return this.auth.changePassword(userId, changePasswordDto);
  }

  @Post('2fa/setup')
  @UseGuards(AuthGuard('jwt'))
  setup2FA(@Request() req) {
    const userId = req.user.userId;
    return this.auth.setup2FA(userId);
  }

  @Post('2fa/verify-and-enable')
  @UseGuards(AuthGuard('jwt'))
  verifyAndEnable2FA(@Request() req, @Body(ValidationPipe) dto: Verify2faDto) {
    const userId = req.user.userId;
    return this.auth.verifyAndEnable2FA(userId, dto.code);
  }

  @Post('2fa/login-verify')
  @HttpCode(200)
  login2FA(@Body(ValidationPipe) dto: Login2faDto) {
    return this.auth.login2fa(dto.tempToken, dto.code);
  }
}

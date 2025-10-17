import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';

@Injectable()
export class JwtRefreshStrategy extends PassportStrategy(
  Strategy,
  'jwt-refresh',
) {
  constructor(private readonly configService: ConfigService) {
    const secret = configService.get('JWT_REFRESH_SECRET');
    if (!secret) {
      throw new Error('El secreto del JWT Refresh no está definido.');
    }

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
      passReqToCallback: true,
    });
  }

  validate(req: Request, payload: { sub: string; email: string }) {
    const authHeader = req.get('authorization');

    if (!authHeader) {
      throw new UnauthorizedException('No se encontró el token de refresco.');
    }

    const refreshToken = authHeader.replace('Bearer', '').trim();

    return {
      userId: payload.sub,
      email: payload.email,
      refreshToken,
    };
  }
}

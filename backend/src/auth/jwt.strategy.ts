import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(private readonly configService: ConfigService) {
    const secret = configService.get('JWT_ACCESS_SECRET');

    if (!secret) {
      throw new Error(
        'El secreto del JWT no está definido en las variables de entorno.',
      );
    }

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
    });
  }

  async validate(payload: {
    sub: string;
    email: string;
    run: string;
    tipo_usuario: string;
  }) {
    return {
      userId: payload.sub,
      email: payload.email,
      run: payload.run,
      tipo_usuario: payload.tipo_usuario,
    };
  }
}

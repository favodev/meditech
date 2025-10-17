import { Module } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { JwtStrategy } from './jwt.strategy';
import { UsuarioModule } from 'src/usuario/usuario.module';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtRefreshStrategy } from './jwt-refresh.strategy';

@Module({
  imports: [
    UsuarioModule,
    PassportModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        return {
          secret: configService.get('JWT_ACCESS_SECRET'),
          signOptions: {
            expiresIn: configService.get('JWT_ACCESS_EXPIRATION'),
          },
        };
      },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, JwtRefreshStrategy],
  exports: [PassportModule, JwtModule],
})
export class AuthModule {}

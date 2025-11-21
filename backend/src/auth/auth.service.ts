import {
  ForbiddenException,
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Usuario } from '@usuario/entities/usuario.schema';
import { LoginDto } from './dto/login.dto';
import * as bcrypt from 'bcrypt';
import { InjectModel } from '@nestjs/mongoose';

import { Model, Types } from 'mongoose';

import { UnifiedRegisterDto } from './dto/unified-register.dto';
import { TipoUsuario } from '@enums/tipo_usuario.enum';
import { ChangePasswordDto } from './dto/change-password.dto';
import { authenticator } from 'otplib';
import * as qrcode from 'qrcode';
import { MailerService } from '@nestjs-modules/mailer';
import * as crypto from 'crypto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    @InjectModel(Usuario.name) private userModel: Model<Usuario>,
    private readonly mailService: MailerService,
  ) {}

  async login(dto: LoginDto) {
    const user = await this.validateUser(dto);

    if (user.isTwoFactorEnabled) {
      const payload = {
        sub: user.id,
        email: user.email,
        is2faTempToken: true,
      };

      const tempToken = await this.jwtService.signAsync(payload, {
        secret: this.configService.get('JWT_ACCESS_SECRET'),
        expiresIn: '5m',
      });

      return {
        needs2fa: true,
        tempToken: tempToken,
      };
    }

    const tokens = await this.getTokens(
      (user._id as Types.ObjectId).toString(),
      user.email,
      user.run,
      user.tipo_usuario,
    );

    await this.updateRefreshTokenHash(
      (user._id as Types.ObjectId).toString(),
      tokens.refreshToken,
    );

    return {
      needs2fa: false,
      ...tokens,
    };
  }

  async register(dto: UnifiedRegisterDto): Promise<any> {
    const hash = await bcrypt.hash(dto.password, 10);

    const user = new this.userModel({
      tipo_usuario: dto.tipo_usuario,
      nombre: dto.nombre,
      apellido: dto.apellido,
      email: dto.email,
      telefono: dto.telefono,
      password_hash: hash,
      run: dto.run,
    });

    switch (dto.tipo_usuario) {
      case TipoUsuario.MEDICO:
        Object.assign(user, dto.medico_detalle);
        break;
      case TipoUsuario.PACIENTE:
        Object.assign(user, dto.paciente_detalle);
        break;
      default:
        throw new UnauthorizedException('Tipo de usuario no válido');
    }

    return user.save();
  }

  async refreshToken(userId: string, refreshToken: string) {
    const user = await this.userModel.findById(userId);

    if (!user || !user.currentHashedRefreshToken) {
      throw new UnauthorizedException('Acceso denegado.');
    }

    const refreshTokenMatches = await bcrypt.compare(
      refreshToken,
      user.currentHashedRefreshToken,
    );

    if (!refreshTokenMatches) {
      throw new UnauthorizedException('Acceso denegado.');
    }

    const tokens = await this.getTokens(
      (user._id as Types.ObjectId).toString(),
      user.email,
      user.run,
      user.tipo_usuario,
    );

    await this.updateRefreshTokenHash(
      (user._id as Types.ObjectId).toString(),
      tokens.refreshToken,
    );
    return tokens;
  }

  async logout(userId: string): Promise<boolean> {
    await this.userModel.findByIdAndUpdate(userId, {
      currentHashedRefreshToken: null,
    });
    return true;
  }

  async changePassword(userId: string, changePasswordDto: ChangePasswordDto) {
    const user = await this.userModel.findById(userId);

    if (!user) {
      throw new UnauthorizedException('Usuario no encontrado.');
    }
    const passwordMatches = await bcrypt.compare(
      changePasswordDto.currentPassword,
      user.password_hash,
    );

    if (!passwordMatches) {
      throw new ForbiddenException('La contraseña actual es incorrecta.');
    }

    const newHashedPassword = await bcrypt.hash(
      changePasswordDto.newPassword,
      10,
    );

    await this.userModel.findByIdAndUpdate(userId, {
      password_hash: newHashedPassword,
      currentHashedRefreshToken: null,
    });

    return {
      message:
        'Contraseña actualizada con éxito. Por favor, inicie sesión de nuevo.',
    };
  }

  private async validateUser(dto: LoginDto) {
    const user = await this.userModel.findOne({ email: dto.email });
    const ok = user && (await bcrypt.compare(dto.password, user.password_hash));
    if (!ok) throw new UnauthorizedException('Credenciales inválidas');
    return user;
  }

  private async updateRefreshTokenHash(userId: string, refreshToken: string) {
    const hash = await bcrypt.hash(refreshToken, 10);
    await this.userModel.findByIdAndUpdate(userId, {
      currentHashedRefreshToken: hash,
    });
  }

  private async getTokens(
    userId: string,
    email: string,
    run: string,
    tipo_usuario: string,
  ) {
    const payload = { sub: userId, email, run, tipo_usuario };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.configService.get('JWT_ACCESS_SECRET'),
        expiresIn: this.configService.get('JWT_ACCESS_EXPIRATION'),
      }),

      this.jwtService.signAsync(payload, {
        secret: this.configService.get('JWT_REFRESH_SECRET'),
        expiresIn: this.configService.get('JWT_REFRESH_EXPIRATION'),
      }),
    ]);

    return {
      accessToken,
      refreshToken,
    };
  }

  async setup2FA(userId: string) {
    const user = await this.userModel.findById(userId);
    if (!user) throw new UnauthorizedException('Usuario no encontrado');

    const secret = authenticator.generateSecret();

    const appName = 'Meditech';

    const otpauthUrl = authenticator.keyuri(user.email, appName, secret);

    await this.userModel.findByIdAndUpdate(userId, {
      twoFactorSecret: secret,
      isTwoFactorEnabled: false,
    });

    return {
      qrCodeDataUrl: await qrcode.toDataURL(otpauthUrl),
      secret: secret,
    };
  }

  async verifyAndEnable2FA(userId: string, code: string) {
    const user = await this.userModel.findById(userId);
    if (!user) throw new UnauthorizedException('Usuario no encontrado');

    if (!user.twoFactorSecret) {
      throw new ForbiddenException(
        '2FA no ha sido configurado. Primero llame a /2fa/setup.',
      );
    }

    const isValid = authenticator.verify({
      token: code,
      secret: user.twoFactorSecret,
    });

    if (!isValid) {
      throw new ForbiddenException('Código 2FA inválido.');
    }

    await this.userModel.findByIdAndUpdate(userId, {
      isTwoFactorEnabled: true,
    });

    return {
      message: '2FA ha sido habilitado exitosamente.',
    };
  }

  async login2fa(tempToken: string, code: string) {
    let payload: any;

    try {
      payload = await this.jwtService.verifyAsync(tempToken, {
        secret: this.configService.get('JWT_ACCESS_SECRET'),
      });
    } catch (error) {
      throw new UnauthorizedException('Token 2FA inválido o expirado.');
    }

    if (!payload.is2faTempToken) {
      throw new UnauthorizedException('Token inválido.');
    }

    const userId = payload.sub;
    const user = await this.userModel.findById(userId);
    if (!user || !user.isTwoFactorEnabled || !user.twoFactorSecret) {
      throw new UnauthorizedException(
        'Usuario no encontrado o 2FA no habilitado.',
      );
    }

    const isValid = authenticator.verify({
      token: code,
      secret: user.twoFactorSecret,
    });

    if (!isValid) {
      throw new UnauthorizedException('Código 2FA incorrecto.');
    }

    const tokens = await this.getTokens(
      userId,
      user.email,
      user.run,
      user.tipo_usuario,
    );
    await this.updateRefreshTokenHash(userId, tokens.refreshToken);

    return {
      ...tokens,
    };
  }

  async forgotPassword(dto: ForgotPasswordDto) {
    const user = await this.userModel.findOne({ email: dto.email });

    // Por seguridad, respondemos éxito aunque el email no exista
    if (!user) {
      return { message: 'Si el correo existe, se ha enviado un enlace.' };
    }

    // Generar token
    const resetToken = Math.floor(100000 + Math.random() * 900000).toString();
    const resetTokenHash = crypto
      .createHash('sha256')
      .update(resetToken)
      .digest('hex');

    user.passwordResetToken = resetTokenHash;
    user.passwordResetExpires = new Date(Date.now() + 15 * 60 * 1000); // 15 min

    await user.save();

    // 2. ENVIAR EL CORREO REAL
    try {
      await this.mailService.sendMail({
        to: user.email,
        subject: 'Recuperación de Contraseña - Meditech',
        html: `
          <div style="font-family: Arial, sans-serif; text-align: center;">
            <h2>Recuperación de Contraseña</h2>
            <p>Hola ${user.nombre}, usa el siguiente código en la App para restablecer tu clave:</p>
            
            <div style="background-color: #f3f4f6; padding: 20px; margin: 20px 0; font-size: 24px; font-weight: bold; letter-spacing: 5px; border-radius: 8px;">
              ${resetToken}
            </div>

            <p>Este código expira en 15 minutos.</p>
            <p style="font-size: 12px; color: #888;">Si no solicitaste esto, ignora este mensaje.</p>
          </div>
          `,
      });
    } catch (error) {
      console.error('Error enviando email:', error);
      throw new InternalServerErrorException('Error al enviar correo');
    }

    return { message: 'Si el correo existe, se ha enviado un enlace.' };
  }

  async resetPassword(dto: ResetPasswordDto) {
    // 1. Hasheamos el token que recibimos para poder buscarlo en la BD
    // (Usamos crypto aquí porque necesitamos un hash determinista para la búsqueda)
    const hashedToken = crypto
      .createHash('sha256')
      .update(dto.token)
      .digest('hex');

    // 2. Buscamos al usuario que tenga ese token Y que no haya expirado
    const user = await this.userModel.findOne({
      passwordResetToken: hashedToken,
      passwordResetExpires: { $gt: Date.now() }, // Debe ser mayor a "ahora"
    });

    if (!user) {
      throw new UnauthorizedException('El token es inválido o ha expirado.');
    }

    // 3. AQUÍ USAMOS BCRYPT (Tu librería)
    // Encriptamos la nueva contraseña igual que en el registro
    const newPasswordHash = await bcrypt.hash(dto.newPassword, 10);

    // 4. Actualizamos el usuario
    user.password_hash = newPasswordHash;

    // 5. Limpiamos los campos de recuperación (para que el token no se use 2 veces)
    user.passwordResetToken = undefined;
    user.passwordResetExpires = undefined;

    // Opcional: Invalidar sesiones abiertas cambiando el refresh token
    user.currentHashedRefreshToken = undefined;

    await user.save();

    return {
      message:
        'Contraseña actualizada correctamente. Ya puedes iniciar sesión.',
    };
  }
}

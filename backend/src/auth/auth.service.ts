import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Usuario } from 'src/usuario/entities/usuario.schema';
import { LoginDto } from './dto/login.dto';
import * as bcrypt from 'bcrypt';
import { InjectModel } from '@nestjs/mongoose';

import { Model, Types } from 'mongoose';

import { UnifiedRegisterDto } from './dto/unified-register.dto';
import { TipoUsuario } from 'src/common/enums/tipo_usuario.enum';
import { ChangePasswordDto } from './dto/change-password.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    @InjectModel(Usuario.name) private userModel: Model<Usuario>,
  ) {}

  async login(dto: LoginDto) {
    const user = await this.validateUser(dto);

    const tokens = await this.getTokens(
      (user._id as Types.ObjectId).toString(),
      user.email,
      user.run,
    );

    await this.updateRefreshTokenHash(
      (user._id as Types.ObjectId).toString(),
      tokens.refreshToken,
    );

    return {
      usuario: {
        id: user._id,
        nombre: user.nombre,
        email: user.email,
        tipo_usuario: user.tipo_usuario,
      },
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

  private async getTokens(userId: string, email: string, run: string) {
    const payload = { sub: userId, email, run };

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
}

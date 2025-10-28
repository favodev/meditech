import {
  IsEmail,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { TipoUsuario } from '@enums/tipo_usuario.enum';
import { IsRUT } from '@decorator/rut.decorators';

export class RegisterDto {
  @IsString()
  @IsIn(Object.values(TipoUsuario))
  @IsNotEmpty()
  tipo_usuario: string;

  @IsString()
  @IsNotEmpty()
  nombre: string;

  @IsString()
  @IsNotEmpty()
  apellido: string;

  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsString()
  @IsOptional()
  telefono?: string;

  @IsString()
  @MinLength(6)
  @IsNotEmpty()
  password: string;

  @IsRUT()
  @IsString()
  @IsNotEmpty()
  run: string;
}

import {
  IsEmail,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { TipoUsuario } from '@enums/tipo_usuario.enum';
import { IsRUT } from '@decorator/rut.decorators';
import { Type } from 'class-transformer';
import { CreatePacienteDetailsDto } from './create-paciente-details.dto';
import { CreateMedicoDetailsDto } from './create-medico-details.dto';

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

  @IsOptional()
  @IsString()
  telefono?: string;

  @IsString()
  @MinLength(6)
  @IsNotEmpty()
  password: string;

  @IsRUT()
  @IsString()
  @IsNotEmpty()
  run: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => CreatePacienteDetailsDto)
  paciente_detalle?: CreatePacienteDetailsDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => CreateMedicoDetailsDto)
  medico_detalle?: CreateMedicoDetailsDto;
}

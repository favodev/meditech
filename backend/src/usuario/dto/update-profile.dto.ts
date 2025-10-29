import {
  IsString,
  IsOptional,
  IsDate,
  IsEnum,
  IsNumber,
  IsObject,
  ValidateNested,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { Sexo } from '@enums/sexo.enum';

class UpdateInstitucionEmbebidaDto {
  @IsString()
  @IsOptional()
  nombre?: string;

  @IsString()
  @IsOptional()
  tipo?: string;
}

export class UpdateProfileDto {
  @IsString()
  @IsOptional()
  nombre?: string;

  @IsString()
  @IsOptional()
  apellido?: string;

  @IsString()
  @IsOptional()
  telefono?: string;

  @IsEnum(Sexo)
  @IsOptional()
  sexo?: string;

  @IsString()
  @IsOptional()
  direccion?: string;

  @IsDate()
  @IsOptional()
  @Transform(({ value }) => new Date(value))
  fecha_nacimiento?: Date;

  @IsString()
  @IsOptional()
  telefono_emergencia?: string;

  @IsObject()
  @IsOptional()
  @ValidateNested()
  @Type(() => UpdateInstitucionEmbebidaDto)
  institucion?: UpdateInstitucionEmbebidaDto;

  @IsString()
  @IsOptional()
  especialidad?: string;

  @IsString()
  @IsOptional()
  telefono_consultorio?: string;

  @IsNumber()
  @IsOptional()
  anios_experiencia?: number;

  @IsString()
  @IsOptional()
  registro_mpi?: string;
}

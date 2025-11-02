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
  @IsOptional()
  @IsString()
  nombre?: string;

  @IsOptional()
  @IsString()
  tipo?: string;
}

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  nombre?: string;

  @IsOptional()
  @IsString()
  apellido?: string;

  @IsOptional()
  @IsString()
  telefono?: string;

  @IsOptional()
  @IsEnum(Sexo)
  sexo?: string;

  @IsOptional()
  @IsString()
  direccion?: string;

  @IsOptional()
  @IsDate()
  @Transform(({ value }) => new Date(value))
  fecha_nacimiento?: Date;

  @IsOptional()
  @IsString()
  telefono_emergencia?: string;

  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => UpdateInstitucionEmbebidaDto)
  institucion?: UpdateInstitucionEmbebidaDto;

  @IsOptional()
  @IsString()
  especialidad?: string;

  @IsOptional()
  @IsString()
  telefono_consultorio?: string;

  @IsOptional()
  @IsNumber()
  anios_experiencia?: number;

  @IsOptional()
  @IsString()
  registro_mpi?: string;
}

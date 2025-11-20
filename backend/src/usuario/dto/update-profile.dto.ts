import {
  IsString,
  IsOptional,
  IsDate,
  IsEnum,
  IsNumber,
  IsObject,
  ValidateNested,
  Max,
  Min,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { Sexo } from '@enums/sexo.enum';
import { MedicamentoAnticoagulante } from '@enums/medicamento_anticoagulante.enum';

class UpdateRangoMetaDto {
  @IsNumber()
  @Min(1.0)
  @Max(5.0)
  min: number;

  @IsNumber()
  @Min(1.5)
  @Max(6.0)
  max: number;
}

class UpdateDatosAnticoagulacionDto {
  @IsEnum(MedicamentoAnticoagulante)
  @IsString()
  medicamento: MedicamentoAnticoagulante;

  @IsObject()
  @ValidateNested()
  @Type(() => UpdateRangoMetaDto)
  rango_meta: UpdateRangoMetaDto;

  @IsOptional()
  @IsString()
  diagnostico_base?: string;

  @IsOptional()
  @IsDate()
  @Transform(({ value }) => new Date(value))
  fecha_inicio_tratamiento?: Date;
}

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

  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => UpdateDatosAnticoagulacionDto)
  datos_anticoagulacion?: UpdateDatosAnticoagulacionDto;
}

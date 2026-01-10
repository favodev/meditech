import {
  IsDate,
  IsIn,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { Sexo } from '@enums/sexo.enum';
import { MedicamentoAnticoagulante } from '@enums/medicamento_anticoagulante.enum';

class RangoMetaDto {
  @IsNumber()
  @IsNotEmpty()
  min: number;

  @IsNumber()
  @IsNotEmpty()
  max: number;
}

class DatosAnticoagulacionDto {
  @IsString()
  @IsNotEmpty()
  @IsIn(Object.values(MedicamentoAnticoagulante))
  medicamento: string;

  @IsNumber()
  @IsNotEmpty()
  mg_por_pastilla: number;

  @ValidateNested()
  @Type(() => RangoMetaDto)
  @IsNotEmpty()
  rango_meta: RangoMetaDto;

  @IsOptional()
  @IsString()
  diagnostico_base?: string;

  @IsOptional()
  @IsDate()
  @Transform(({ value }) => new Date(value))
  fecha_inicio_tratamiento?: Date;
}

export class CreatePacienteDetailsDto {
  @IsString()
  @IsNotEmpty()
  @IsIn(Object.values(Sexo))
  sexo: string;

  @IsString()
  @IsNotEmpty()
  direccion: string;

  @IsDate()
  @IsNotEmpty()
  @Transform(({ value }) => new Date(value))
  fecha_nacimiento: Date;

  @IsOptional()
  @IsString()
  telefono_emergencia?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => DatosAnticoagulacionDto)
  datos_anticoagulacion?: DatosAnticoagulacionDto;
}

import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsNumber,
  IsDate,
  ValidateNested,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';
import { IsRUT } from '@decorator/rut.decorators';

class CalendarioDosisDto {
  @IsString() @IsNotEmpty() lunes: string;
  @IsString() @IsNotEmpty() martes: string;
  @IsString() @IsNotEmpty() miercoles: string;
  @IsString() @IsNotEmpty() jueves: string;
  @IsString() @IsNotEmpty() viernes: string;
  @IsString() @IsNotEmpty() sabado: string;
  @IsString() @IsNotEmpty() domingo: string;
}

class ContenidoClinicoDto {
  @IsOptional()
  @IsNumber()
  @Min(0.5)
  @Max(20.0)
  inr_actual?: number;

  @IsOptional()
  @IsDate()
  @Type(() => Date) // Transforma el string ISO a objeto Date automáticamente
  fecha_proximo_control?: Date;

  @IsOptional()
  @ValidateNested()
  @Type(() => CalendarioDosisDto)
  dosis_diaria?: CalendarioDosisDto;

  @IsOptional()
  @IsNumber()
  dosis_semanal_total_mg?: number;

  @IsOptional()
  @IsString()
  observaciones_clinicas?: string;
}

export class CreateInformeDto {
  @IsString()
  @IsNotEmpty()
  titulo: string;

  @IsString()
  @IsNotEmpty()
  tipo_informe: string;

  @IsOptional()
  @IsString()
  observaciones?: string;

  @IsOptional()
  @IsRUT()
  @IsString()
  run_medico?: string;

  @IsOptional()
  @IsRUT()
  @IsString()
  run_paciente?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => ContenidoClinicoDto)
  contenido_clinico?: ContenidoClinicoDto;
}

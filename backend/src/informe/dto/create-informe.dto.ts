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

// ==========================================
// 1. DTO Auxiliar: Calendario de Dosis (Visual)
// ==========================================
class CalendarioDosisDto {
  // Validamos que lleguen los 7 días. Pueden ser "0" o "Sin dosis", pero no null.
  @IsString() @IsNotEmpty() lunes: string;
  @IsString() @IsNotEmpty() martes: string;
  @IsString() @IsNotEmpty() miercoles: string;
  @IsString() @IsNotEmpty() jueves: string;
  @IsString() @IsNotEmpty() viernes: string;
  @IsString() @IsNotEmpty() sabado: string;
  @IsString() @IsNotEmpty() domingo: string;
}

// ==========================================
// 2. DTO Auxiliar: Contenido Clínico (TACO)
// ==========================================
class ContenidoClinicoDto {
  // INR: Debe ser numérico y en rangos lógicos para evitar errores de dedo (ej. no existe INR 100)
  @IsOptional()
  @IsNumber()
  @Min(0.5)
  @Max(20.0)
  inr_actual?: number;

  // La fecha administrativa
  @IsOptional()
  @IsDate()
  @Type(() => Date) // Transforma el string ISO a objeto Date automáticamente
  fecha_proximo_control?: Date;

  // Validamos que el objeto dosis venga bien formado
  @IsOptional()
  @ValidateNested()
  @Type(() => CalendarioDosisDto)
  dosis_diaria?: CalendarioDosisDto;

  // Opcional: El frontend puede enviarlo calculado, o lo calculas tú en el backend
  @IsOptional()
  @IsNumber()
  dosis_semanal_total_mg?: number;

  @IsOptional()
  @IsString()
  observaciones_clinicas?: string;
}

// ==========================================
// 3. DTO Principal: Crear Informe
// ==========================================
export class CreateInformeDto {
  @IsString()
  @IsNotEmpty()
  titulo: string;

  @IsString()
  @IsNotEmpty()
  tipo_informe: string; // Ej: "Control de Anticoagulación"

  @IsOptional()
  @IsString()
  observaciones?: string;

  // --- Lógica de Autoría (Lo que arreglamos antes) ---

  // Obligatorio si lo crea el PACIENTE
  @IsOptional()
  @IsRUT()
  @IsString()
  run_medico?: string;

  // Obligatorio si lo crea el MÉDICO
  @IsOptional()
  @IsRUT()
  @IsString()
  run_paciente?: string;

  // --- EL NUEVO CAMPO INTELIGENTE ---
  // Opcional: Solo se envía si es un informe de tipo TACO
  @IsOptional()
  @ValidateNested()
  @Type(() => ContenidoClinicoDto)
  contenido_clinico?: ContenidoClinicoDto;
}

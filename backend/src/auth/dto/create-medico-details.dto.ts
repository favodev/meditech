import {
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

class CreateInstitucionEmbebidaDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @IsString()
  @IsNotEmpty()
  tipo_institucion: string;
}

export class CreateMedicoDetailsDto {
  @IsObject()
  @IsNotEmpty()
  @ValidateNested()
  @Type(() => CreateInstitucionEmbebidaDto)
  institucion: CreateInstitucionEmbebidaDto;

  @IsString()
  @IsNotEmpty()
  especialidad: string;

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

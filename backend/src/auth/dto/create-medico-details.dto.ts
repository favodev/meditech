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

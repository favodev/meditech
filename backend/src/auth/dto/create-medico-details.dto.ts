import {
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { Especialidades } from '@enums/especialidades.enum';
import { TipoInstitucion } from '@enums/tipo_institucion.enum';

class CreateInstitucionEmbebidaDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @IsEnum(TipoInstitucion)
  @IsNotEmpty()
  tipo_institucion: string;
}

export class CreateMedicoDetailsDto {
  @IsObject()
  @IsNotEmpty()
  @ValidateNested()
  @Type(() => CreateInstitucionEmbebidaDto)
  institucion: CreateInstitucionEmbebidaDto;

  @IsEnum(Especialidades)
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

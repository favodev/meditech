import {
  IsString,
  IsOptional,
  IsDate,
  IsIn,
  IsEnum,
  IsNumber,
  IsObject,
  ValidateNested,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { Sexo } from '../../common/enums/sexo.enum';
import { Especialidades } from 'src/common/enums/especialidades.enum';
import { TipoInstitucion } from 'src/common/enums/tipo_institucion.enum';

class UpdateInstitucionEmbebidaDto {
  @IsString()
  @IsOptional()
  nombre?: string;

  @IsEnum(TipoInstitucion)
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

  @IsEnum(Especialidades)
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

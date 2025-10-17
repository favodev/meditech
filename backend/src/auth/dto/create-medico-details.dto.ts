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
import { Especialidades } from 'src/common/enums/especialidades.enum';
import { TipoInstitucion } from 'src/common/enums/tipo_institucion.enum';

// DTO para el objeto de institución anidado que se espera en el body
class CreateInstitucionEmbebidaDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @IsEnum(TipoInstitucion)
  @IsNotEmpty()
  tipo_institucion: string;
}

export class CreateMedicoDetailsDto {
  // 👇 CAMBIO 1: Ahora es un objeto, no un MongoId
  @IsObject()
  @IsNotEmpty()
  @ValidateNested() // Le dice a class-validator que valide el objeto anidado
  @Type(() => CreateInstitucionEmbebidaDto) // Le dice a class-transformer cómo mapear el objeto
  institucion: CreateInstitucionEmbebidaDto;

  // 👇 CAMBIO 2: Ahora es un string validado por el enum, no un MongoId
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

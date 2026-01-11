import {
  IsEnum,
  IsMongoId,
  IsNotEmpty,
  IsOptional,
  IsDate,
  IsArray,
  ValidateNested,
  IsString,
} from 'class-validator';
import { Type } from 'class-transformer';
import { NivelAcceso } from '@enums/nivel_acceso.enum';
import { IsRUT } from '@decorator/rut.decorators';

class ArchivoCompartidoDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @IsString()
  @IsNotEmpty()
  formato: string;

  @IsString()
  @IsNotEmpty()
  urlpath: string;

  @IsString()
  @IsNotEmpty()
  tipo: string;
}

export class CreatePermisoCompartirDto {
  @IsEnum(NivelAcceso)
  @IsNotEmpty()
  nivel_acceso: NivelAcceso;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  fecha_limite?: Date;

  @IsRUT()
  @IsString()
  @IsNotEmpty()
  run_medico: string;

  @IsMongoId()
  @IsNotEmpty()
  informe_id_original: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ArchivoCompartidoDto)
  archivos?: ArchivoCompartidoDto[];
}

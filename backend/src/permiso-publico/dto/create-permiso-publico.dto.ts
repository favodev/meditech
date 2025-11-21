import {
  IsEnum,
  IsMongoId,
  IsNotEmpty,
  IsArray,
  ValidateNested,
  IsString,
  IsOptional,
} from 'class-validator';
import { Type } from 'class-transformer';
import { NivelAcceso } from '@enums/nivel_acceso.enum';

class ArchivoPublicoDto {
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

export class CreatePermisoPublicoDto {
  @IsEnum(NivelAcceso)
  @IsNotEmpty()
  nivel_acceso: NivelAcceso;

  @IsMongoId()
  @IsNotEmpty()
  informe_id_original: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ArchivoPublicoDto)
  archivos?: ArchivoPublicoDto[];
}

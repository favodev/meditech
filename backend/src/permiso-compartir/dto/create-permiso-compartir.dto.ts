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
import { NivelAcceso } from '../../common/enums/nivel_acceso.enum';

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
}

export class CreatePermisoCompartirDto {
  @IsEnum(NivelAcceso)
  @IsNotEmpty()
  nivel_acceso: NivelAcceso;

  @IsDate()
  @Type(() => Date)
  fecha_limite?: Date;

  @IsString()
  @IsNotEmpty()
  run_medico: string;

  @IsMongoId()
  @IsNotEmpty()
  informe_id_original: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ArchivoCompartidoDto)
  @IsOptional()
  archivos?: ArchivoCompartidoDto[];
}

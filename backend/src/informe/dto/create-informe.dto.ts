import { IsString, IsNotEmpty, IsEnum, IsOptional } from 'class-validator';
import { TipoInforme } from '@enums/tipo_informe.enum';

export class CreateInformeDto {
  @IsString()
  @IsNotEmpty()
  titulo: string;

  @IsEnum(TipoInforme)
  @IsNotEmpty()
  tipo_informe: string;

  @IsString()
  @IsOptional()
  observaciones?: string;

  @IsString()
  @IsNotEmpty()
  run_medico: string;
}

import { IsString, IsNotEmpty, IsOptional } from 'class-validator';
import { IsRUT } from '@decorator/rut.decorators';

export class CreateInformeDto {
  @IsString()
  @IsNotEmpty()
  titulo: string;

  @IsString()
  @IsNotEmpty()
  tipo_informe: string;

  @IsOptional()
  @IsString()
  observaciones?: string;

  @IsRUT()
  @IsString()
  @IsNotEmpty()
  run_medico: string;
}

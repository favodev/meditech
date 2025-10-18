import {
  IsString,
  IsNotEmpty,
  IsEnum,
  IsOptional,
  // Validador para RUN chileno (deberás instalarlo o crearlo)
  // import { IsRut } from 'your-custom-validator-package';
} from 'class-validator';
import { TipoInforme } from '../../common/enums/tipo_informe.enum';

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

  // @IsRut() // Descomenta si tienes un validador de RUN
  @IsString() // Temporalmente como string si no tienes validador
  @IsNotEmpty()
  run_medico: string; // 👈 Campo nuevo: RUN del médico asociado
}

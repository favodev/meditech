import { IsString, IsIn, IsNotEmpty } from 'class-validator';
import { TipoInstitucion } from '../../common/enums/tipo_institucion.enum';

export class CreateInstitucionDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @IsString()
  @IsIn(Object.values(TipoInstitucion))
  @IsNotEmpty()
  tipo_institucion: string;
}

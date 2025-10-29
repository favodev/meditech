import { IsString, IsNotEmpty } from 'class-validator';

export class CreateTipoInstitucionDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;
}

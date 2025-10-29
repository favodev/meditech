import { IsString, IsNotEmpty } from 'class-validator';

export class CreateTipoArchivoDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;
}

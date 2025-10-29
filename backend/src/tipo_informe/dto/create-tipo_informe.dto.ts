import { IsString, IsNotEmpty } from 'class-validator';

export class CreateTipoInformeDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;
}

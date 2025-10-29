import { IsString, IsNotEmpty } from 'class-validator';

export class CreateEpecialidadDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;
}

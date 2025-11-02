import {
  IsDate,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { Sexo } from '@enums/sexo.enum';

export class CreatePacienteDetailsDto {
  @IsString()
  @IsNotEmpty()
  @IsIn(Object.values(Sexo))
  sexo: string;

  @IsString()
  @IsNotEmpty()
  direccion: string;

  @IsDate()
  @IsNotEmpty()
  @Transform(({ value }) => new Date(value))
  fecha_nacimiento: Date;

  @IsOptional()
  @IsString()
  telefono_emergencia?: string;
}

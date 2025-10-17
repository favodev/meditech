import { Type } from 'class-transformer';
import {
  IsNotEmpty,
  IsObject,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import { RegisterDto } from './register.dto'; // Tu DTO base
import { CreatePacienteDetailsDto } from './create-paciente-details.dto';
import { CreateMedicoDetailsDto } from './create-medico-details.dto';
import { TipoUsuario } from '../../common/enums/tipo_usuario.enum';

export class UnifiedRegisterDto extends RegisterDto {
  @ValidateIf((o) => o.tipo_usuario === TipoUsuario.PACIENTE)
  @IsNotEmpty()
  @IsObject()
  @ValidateNested()
  @Type(() => CreatePacienteDetailsDto)
  paciente_detalle: CreatePacienteDetailsDto;

  @ValidateIf((o) => o.tipo_usuario === TipoUsuario.MEDICO)
  @IsNotEmpty()
  @IsObject()
  @ValidateNested()
  @Type(() => CreateMedicoDetailsDto)
  medico_detalle: CreateMedicoDetailsDto;
}

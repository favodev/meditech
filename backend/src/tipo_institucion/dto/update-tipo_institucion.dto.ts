import { PartialType } from '@nestjs/mapped-types';
import { CreateTipoInstitucionDto } from './create-tipo_institucion.dto';

export class UpdateTipoInstitucionDto extends PartialType(CreateTipoInstitucionDto) {}

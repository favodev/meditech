import { PartialType } from '@nestjs/mapped-types';
import { CreatePermisoCompartirDto } from './create-permiso-compartir.dto';

export class UpdatePermisoCompartirDto extends PartialType(CreatePermisoCompartirDto) {}

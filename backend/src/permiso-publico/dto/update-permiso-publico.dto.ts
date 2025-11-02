import { PartialType } from '@nestjs/mapped-types';
import { CreatePermisoPublicoDto } from './create-permiso-publico.dto';

export class UpdatePermisoPublicoDto extends PartialType(CreatePermisoPublicoDto) {}

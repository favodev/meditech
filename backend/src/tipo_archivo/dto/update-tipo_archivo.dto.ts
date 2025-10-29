import { PartialType } from '@nestjs/mapped-types';
import { CreateTipoArchivoDto } from './create-tipo_archivo.dto';

export class UpdateTipoArchivoDto extends PartialType(CreateTipoArchivoDto) {}

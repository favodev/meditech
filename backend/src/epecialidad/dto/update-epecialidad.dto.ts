import { PartialType } from '@nestjs/mapped-types';
import { CreateEpecialidadDto } from './create-epecialidad.dto';

export class UpdateEpecialidadDto extends PartialType(CreateEpecialidadDto) {}

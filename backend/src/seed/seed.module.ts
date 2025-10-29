import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SeedService } from './seed.service';
import { SeedController } from './seed.controller';
import {
  Especialidad,
  EspecialidadSchema,
} from '@modules/epecialidad/entities/epecialidad.schema';
import {
  TipoArchivo,
  TipoArchivoSchema,
} from '@modules/tipo_archivo/entities/tipo_archivo.schema';
import {
  TipoInforme,
  TipoInformeSchema,
} from '@modules/tipo_informe/entities/tipo_informe.schema';
import {
  TipoInstitucion,
  TipoInstitucionSchema,
} from '@modules/tipo_institucion/entities/tipo_institucion.schema';
import {
  Institucion,
  InstitucionSchema,
} from '@modules/institucion/entities/institucion.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Especialidad.name, schema: EspecialidadSchema },
      { name: TipoArchivo.name, schema: TipoArchivoSchema },
      { name: TipoInforme.name, schema: TipoInformeSchema },
      { name: TipoInstitucion.name, schema: TipoInstitucionSchema },
      { name: Institucion.name, schema: InstitucionSchema },
    ]),
  ],
  controllers: [SeedController],
  providers: [SeedService],
})
export class SeedModule {}

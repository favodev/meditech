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
import {
  Usuario,
  UsuarioSchema,
} from '@modules/usuario/entities/usuario.schema';
import {
  Informe,
  InformeSchema,
} from '@modules/informe/entities/informe.schema';
import { StorageModule } from '@modules/storage/storage.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Especialidad.name, schema: EspecialidadSchema },
      { name: TipoArchivo.name, schema: TipoArchivoSchema },
      { name: TipoInforme.name, schema: TipoInformeSchema },
      { name: TipoInstitucion.name, schema: TipoInstitucionSchema },
      { name: Institucion.name, schema: InstitucionSchema },
      { name: Usuario.name, schema: UsuarioSchema },
      { name: Informe.name, schema: InformeSchema },
    ]),
    StorageModule,
  ],
  controllers: [SeedController],
  providers: [SeedService],
})
export class SeedModule {}

import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SeedService } from './seed.service';
import { SeedController } from './seed.controller';
import {
  Especialidad,
  EspecialidadSchema,
} from '@especialidad/entities/especialidad.schema';
import {
  TipoArchivo,
  TipoArchivoSchema,
} from '@tipo_archivo/entities/tipo_archivo.schema';
import {
  TipoInforme,
  TipoInformeSchema,
} from '@tipo_informe/entities/tipo_informe.schema';
import {
  TipoInstitucion,
  TipoInstitucionSchema,
} from '@tipo_institucion/entities/tipo_institucion.schema';
import {
  Institucion,
  InstitucionSchema,
} from '@institucion/entities/institucion.schema';
import { Usuario, UsuarioSchema } from '@usuario/entities/usuario.schema';
import { Informe, InformeSchema } from '@informe/entities/informe.schema';
import { StorageModule } from '@storage/storage.module';

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

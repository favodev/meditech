import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PermisoPublicoService } from './permiso-publico.service';
import { PermisoPublicoController } from './permiso-publico.controller';
import {
  PermisoPublico,
  PermisoPublicoSchema,
} from './entities/permiso-publico.schema';
import { InformeModule } from '@informe/informe.module';
import { StorageModule } from '@storage/storage.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: PermisoPublico.name, schema: PermisoPublicoSchema },
    ]),
    InformeModule,
    StorageModule,
  ],
  controllers: [PermisoPublicoController],
  providers: [PermisoPublicoService],
})
export class PermisoPublicoModule {}

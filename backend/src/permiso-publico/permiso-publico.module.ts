import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PermisoPublicoService } from './permiso-publico.service';
import { PermisoPublicoController } from './permiso-publico.controller';
import {
  PermisoPublico,
  PermisoPublicoSchema,
} from './entities/permiso-publico.schema';
import { InformeModule } from '@modules/informe/informe.module';
import { StorageModule } from '@modules/storage/storage.module';

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

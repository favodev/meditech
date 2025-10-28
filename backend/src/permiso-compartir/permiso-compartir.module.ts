import { Module } from '@nestjs/common';
import { PermisoCompartirService } from './permiso-compartir.service';
import { PermisoCompartirController } from './permiso-compartir.controller';
import { MongooseModule } from '@nestjs/mongoose';
import { StorageModule } from '@modules/storage/storage.module';
import {
  PermisoCompartir,
  PermisoCompartirSchema,
} from './entities/permiso-compartir.schema';
import { InformeModule } from '@modules/informe/informe.module';

@Module({
  imports: [
    InformeModule,
    MongooseModule.forFeature([
      { name: PermisoCompartir.name, schema: PermisoCompartirSchema },
    ]),
    StorageModule,
  ],
  controllers: [PermisoCompartirController],
  providers: [PermisoCompartirService],
})
export class PermisoCompartirModule {}

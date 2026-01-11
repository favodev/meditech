import { Module } from '@nestjs/common';
import { PermisoCompartirService } from './permiso-compartir.service';
import { PermisoCompartirController } from './permiso-compartir.controller';
import { MongooseModule } from '@nestjs/mongoose';
import { StorageModule } from '@storage/storage.module';
import {
  PermisoCompartir,
  PermisoCompartirSchema,
} from './entities/permiso-compartir.schema';
import { InformeModule } from '@informe/informe.module';
import { UsuarioModule } from '@usuario/usuario.module';

@Module({
  imports: [
    InformeModule,
    UsuarioModule,
    MongooseModule.forFeature([
      { name: PermisoCompartir.name, schema: PermisoCompartirSchema },
    ]),
    StorageModule,
  ],
  controllers: [PermisoCompartirController],
  providers: [PermisoCompartirService],
})
export class PermisoCompartirModule {}

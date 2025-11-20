import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { InformeService } from './informe.service';
import { InformeController } from './informe.controller';
import { Informe, InformeSchema } from './entities/informe.schema';
import { StorageModule } from '@storage/storage.module';
import { UsuarioModule } from '@modules/usuario/usuario.module';
import { EstadisticasService } from './estadisticas.service';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Informe.name, schema: InformeSchema }]),
    StorageModule,
    UsuarioModule,
  ],
  controllers: [InformeController],
  providers: [InformeService, EstadisticasService],
  exports: [MongooseModule],
})
export class InformeModule {}

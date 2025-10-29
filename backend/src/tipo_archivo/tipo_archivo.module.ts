import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TipoArchivoService } from './tipo_archivo.service';
import { TipoArchivoController } from './tipo_archivo.controller';
import { TipoArchivo, TipoArchivoSchema } from './entities/tipo_archivo.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: TipoArchivo.name, schema: TipoArchivoSchema },
    ]),
  ],
  controllers: [TipoArchivoController],
  providers: [TipoArchivoService],
  exports: [TipoArchivoService],
})
export class TipoArchivoModule {}

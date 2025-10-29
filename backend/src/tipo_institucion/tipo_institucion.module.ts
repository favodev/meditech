import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TipoInstitucionService } from './tipo_institucion.service';
import { TipoInstitucionController } from './tipo_institucion.controller';
import {
  TipoInstitucion,
  TipoInstitucionSchema,
} from './entities/tipo_institucion.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: TipoInstitucion.name, schema: TipoInstitucionSchema },
    ]),
  ],
  controllers: [TipoInstitucionController],
  providers: [TipoInstitucionService],
  exports: [TipoInstitucionService],
})
export class TipoInstitucionModule {}

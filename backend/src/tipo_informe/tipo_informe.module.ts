import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TipoInformeService } from './tipo_informe.service';
import { TipoInformeController } from './tipo_informe.controller';
import { TipoInforme, TipoInformeSchema } from './entities/tipo_informe.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: TipoInforme.name, schema: TipoInformeSchema },
    ]),
  ],
  controllers: [TipoInformeController],
  providers: [TipoInformeService],
  exports: [TipoInformeService],
})
export class TipoInformeModule {}

import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { InformeService } from './informe.service';
import { InformeController } from './informe.controller';
import { Informe, InformeSchema } from './entities/informe.schema';
import { StorageModule } from '../storage/storage.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Informe.name, schema: InformeSchema }]),
    StorageModule,
  ],
  controllers: [InformeController],
  providers: [InformeService],
  exports: [MongooseModule],
})
export class InformeModule {}

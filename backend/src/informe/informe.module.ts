import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { InformeService } from './informe.service';
import { InformeController } from './informe.controller';
import { Informe, InformeSchema } from './entities/informe.schema';
import { StorageModule } from '../storage/storage.module'; // 👈 Importar StorageModule

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Informe.name, schema: InformeSchema }]),
    StorageModule, // 👈 Añadir StorageModule a los imports
  ],
  controllers: [InformeController],
  providers: [InformeService],
})
export class InformeModule {}

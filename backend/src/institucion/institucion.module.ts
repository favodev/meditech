import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { InstitucionService } from './institucion.service';
import { InstitucionController } from './institucion.controller';
import { Institucion, InstitucionSchema } from './entities/institucion.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Institucion.name, schema: InstitucionSchema },
    ]),
  ],
  controllers: [InstitucionController],
  providers: [InstitucionService],
  exports: [InstitucionService, MongooseModule],
})
export class InstitucionModule {}

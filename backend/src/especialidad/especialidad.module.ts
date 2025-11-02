import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { EspecialidadService } from './especialidad.service';
import { EspecialidadController } from './especialidad.controller';
import {
  Especialidad,
  EspecialidadSchema,
} from './entities/especialidad.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Especialidad.name, schema: EspecialidadSchema },
    ]),
  ],
  controllers: [EspecialidadController],
  providers: [EspecialidadService],
  exports: [EspecialidadService],
})
export class EspecialidadModule {}

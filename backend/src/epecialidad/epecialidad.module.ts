import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { EpecialidadService } from './epecialidad.service';
import { EpecialidadController } from './epecialidad.controller';
import {
  Especialidad,
  EspecialidadSchema,
} from './entities/epecialidad.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Especialidad.name, schema: EspecialidadSchema },
    ]),
  ],
  controllers: [EpecialidadController],
  providers: [EpecialidadService],
  exports: [EpecialidadService],
})
export class EpecialidadModule {}

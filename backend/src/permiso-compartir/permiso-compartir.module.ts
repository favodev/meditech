import { Module } from '@nestjs/common';
import { PermisoCompartirService } from './permiso-compartir.service';
import { PermisoCompartirController } from './permiso-compartir.controller';

@Module({
  controllers: [PermisoCompartirController],
  providers: [PermisoCompartirService],
})
export class PermisoCompartirModule {}

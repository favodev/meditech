import { Module } from '@nestjs/common';
import { InformeService } from './informe.service';
import { InformeController } from './informe.controller';

@Module({
  controllers: [InformeController],
  providers: [InformeService],
})
export class InformeModule {}

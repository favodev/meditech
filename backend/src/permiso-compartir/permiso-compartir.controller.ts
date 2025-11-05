import {
  Controller,
  Post,
  Body,
  UseGuards,
  Request,
  ValidationPipe,
  Get,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { PermisoCompartirService } from './permiso-compartir.service';
import { CreatePermisoCompartirDto } from './dto/create-permiso-compartir.dto';

@Controller('permiso-compartir')
@UseGuards(AuthGuard('jwt'))
export class PermisoCompartirController {
  constructor(private readonly permisoService: PermisoCompartirService) {}

  @Post()
  create(
    @Request() req,
    @Body(ValidationPipe) createPermisoDto: CreatePermisoCompartirDto,
  ) {
    const runPaciente = req.user.run;
    return this.permisoService.create(runPaciente, createPermisoDto);
  }

  @Get('compartidos-conmigo')
  findCompartidosConmigo(@Request() req) {
    const runMedico = req.user.run;
    return this.permisoService.findCompartidosConMedico(runMedico);
  }
}

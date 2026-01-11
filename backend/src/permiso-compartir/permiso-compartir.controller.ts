import {
  Controller,
  Post,
  Body,
  UseGuards,
  Request,
  ValidationPipe,
  Get,
  Patch,
  Param,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { PermisoCompartirService } from './permiso-compartir.service';
import { CreatePermisoCompartirDto } from './dto/create-permiso-compartir.dto';
import { CreateFormalAccessDto } from './dto/create-formal-access.dto';

@Controller('permiso-compartir')
@UseGuards(AuthGuard('jwt'))
export class PermisoCompartirController {
  constructor(private readonly permisoService: PermisoCompartirService) {}

  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() updateDto: { observaciones: string },
    @Request() req
  ) {
    // Ideally validate that req.user.run is the med or patient authorized
    return this.permisoService.updateObservaciones(id, updateDto.observaciones);
  }

  @Post('formal')
  createFormal(@Request() req, @Body() dto: CreateFormalAccessDto) {
    return this.permisoService.createFormalAccess(
      req.user.run,
      dto.doctorRun,
      dto.reportId,
      dto.expiryDays,
    );
  }

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

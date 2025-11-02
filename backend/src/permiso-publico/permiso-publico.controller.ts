import {
  Controller,
  Post,
  Body,
  UseGuards,
  Request,
  ValidationPipe,
  Get,
  Query,
  ForbiddenException,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { PermisoPublicoService } from './permiso-publico.service';
import { CreatePermisoPublicoDto } from './dto/create-permiso-publico.dto';

@Controller('permiso-publico')
export class PermisoPublicoController {
  constructor(private readonly permisoService: PermisoPublicoService) {}

  @Post()
  @UseGuards(AuthGuard('jwt'))
  create(
    @Request() req,
    @Body(ValidationPipe) createPermisoDto: CreatePermisoPublicoDto,
  ) {
    const runPaciente = req.user.run;
    return this.permisoService.create(runPaciente, createPermisoDto);
  }

  @Get('ver')
  async getPublicInforme(@Query('token') token: string) {
    if (!token) {
      throw new ForbiddenException('No se proporcionó un token de acceso.');
    }
    return this.permisoService.getPublicInforme(token);
  }
}

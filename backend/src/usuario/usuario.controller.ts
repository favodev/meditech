import {
  Controller,
  Get,
  Patch,
  Body,
  UseGuards,
  Request,
  ValidationPipe,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { UsuarioService } from './usuario.service';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Controller('usuario')
@UseGuards(AuthGuard('jwt'))
export class UsuarioController {
  constructor(private readonly usuarioService: UsuarioService) {}

  @Get('me')
  findMyProfile(@Request() req) {
    return this.usuarioService.findMyProfile(req.user.userId);
  }

  @Patch('me')
  updateMyProfile(
    @Request() req,
    @Body(new ValidationPipe({ whitelist: true }))
    updateProfileDto: UpdateProfileDto,
  ) {
    return this.usuarioService.updateMyProfile(
      req.user.userId,
      updateProfileDto,
    );
  }

  @Get('dosis-semanal')
  async getDosisSemanal(@Request() req) {
    const userId = req.user.userId;
    return this.usuarioService.calcularDosisSemanal(userId);
  }
}

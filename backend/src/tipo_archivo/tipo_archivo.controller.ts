import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { TipoArchivoService } from './tipo_archivo.service';
import { CreateTipoArchivoDto } from './dto/create-tipo_archivo.dto';
import { UpdateTipoArchivoDto } from './dto/update-tipo_archivo.dto';

@Controller('tipo-archivo')
@UseGuards(AuthGuard('jwt'))
export class TipoArchivoController {
  constructor(private readonly tipoArchivoService: TipoArchivoService) {}

  @Post()
  create(@Body() createTipoArchivoDto: CreateTipoArchivoDto) {
    return this.tipoArchivoService.create(createTipoArchivoDto);
  }

  @Get()
  findAll() {
    return this.tipoArchivoService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.tipoArchivoService.findOne(id);
  }

  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() updateTipoArchivoDto: UpdateTipoArchivoDto,
  ) {
    return this.tipoArchivoService.update(id, updateTipoArchivoDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.tipoArchivoService.remove(id);
  }
}

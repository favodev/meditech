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
import { TipoInstitucionService } from './tipo_institucion.service';
import { CreateTipoInstitucionDto } from './dto/create-tipo_institucion.dto';
import { UpdateTipoInstitucionDto } from './dto/update-tipo_institucion.dto';

@Controller('tipo-institucion')
@UseGuards(AuthGuard('jwt'))
export class TipoInstitucionController {
  constructor(
    private readonly tipoInstitucionService: TipoInstitucionService,
  ) {}

  @Post()
  create(@Body() createTipoInstitucionDto: CreateTipoInstitucionDto) {
    return this.tipoInstitucionService.create(createTipoInstitucionDto);
  }

  @Get()
  findAll() {
    return this.tipoInstitucionService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.tipoInstitucionService.findOne(id);
  }

  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() updateTipoInstitucionDto: UpdateTipoInstitucionDto,
  ) {
    return this.tipoInstitucionService.update(id, updateTipoInstitucionDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.tipoInstitucionService.remove(id);
  }
}

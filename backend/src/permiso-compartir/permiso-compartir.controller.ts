import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { PermisoCompartirService } from './permiso-compartir.service';
import { CreatePermisoCompartirDto } from './dto/create-permiso-compartir.dto';
import { UpdatePermisoCompartirDto } from './dto/update-permiso-compartir.dto';

@Controller('permiso-compartir')
export class PermisoCompartirController {
  constructor(private readonly permisoCompartirService: PermisoCompartirService) {}

  @Post()
  create(@Body() createPermisoCompartirDto: CreatePermisoCompartirDto) {
    return this.permisoCompartirService.create(createPermisoCompartirDto);
  }

  @Get()
  findAll() {
    return this.permisoCompartirService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.permisoCompartirService.findOne(+id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updatePermisoCompartirDto: UpdatePermisoCompartirDto) {
    return this.permisoCompartirService.update(+id, updatePermisoCompartirDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.permisoCompartirService.remove(+id);
  }
}

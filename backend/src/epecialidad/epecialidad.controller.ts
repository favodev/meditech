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
import { EpecialidadService } from './epecialidad.service';
import { CreateEpecialidadDto } from './dto/create-epecialidad.dto';
import { UpdateEpecialidadDto } from './dto/update-epecialidad.dto';

@Controller('epecialidad')
@UseGuards(AuthGuard('jwt'))
export class EpecialidadController {
  constructor(private readonly epecialidadService: EpecialidadService) {}

  @Post()
  create(@Body() createEpecialidadDto: CreateEpecialidadDto) {
    return this.epecialidadService.create(createEpecialidadDto);
  }

  @Get()
  findAll() {
    return this.epecialidadService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.epecialidadService.findOne(id);
  }

  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() updateEpecialidadDto: UpdateEpecialidadDto,
  ) {
    return this.epecialidadService.update(id, updateEpecialidadDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.epecialidadService.remove(id);
  }
}

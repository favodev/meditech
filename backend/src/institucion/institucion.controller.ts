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
import { InstitucionService } from './institucion.service';
import { CreateInstitucionDto } from './dto/create-institucion.dto';
import { UpdateInstitucionDto } from './dto/update-institucion.dto';

@Controller('institucion')
export class InstitucionController {
  constructor(private readonly institucionService: InstitucionService) {}

  @Get()
  findAll() {
    return this.institucionService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.institucionService.findOne(id);
  }

  @Post()
  @UseGuards(AuthGuard('jwt'))
  create(@Body() createInstitucionDto: CreateInstitucionDto) {
    return this.institucionService.create(createInstitucionDto);
  }

  @Patch(':id')
  @UseGuards(AuthGuard('jwt'))
  update(
    @Param('id') id: string,
    @Body() updateInstitucionDto: UpdateInstitucionDto,
  ) {
    return this.institucionService.update(id, updateInstitucionDto);
  }

  @Delete(':id')
  @UseGuards(AuthGuard('jwt'))
  remove(@Param('id') id: string) {
    return this.institucionService.remove(id);
  }
}

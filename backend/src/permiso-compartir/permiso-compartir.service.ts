import { Injectable } from '@nestjs/common';
import { CreatePermisoCompartirDto } from './dto/create-permiso-compartir.dto';
import { UpdatePermisoCompartirDto } from './dto/update-permiso-compartir.dto';

@Injectable()
export class PermisoCompartirService {
  create(createPermisoCompartirDto: CreatePermisoCompartirDto) {
    return 'This action adds a new permisoCompartir';
  }

  findAll() {
    return `This action returns all permisoCompartir`;
  }

  findOne(id: number) {
    return `This action returns a #${id} permisoCompartir`;
  }

  update(id: number, updatePermisoCompartirDto: UpdatePermisoCompartirDto) {
    return `This action updates a #${id} permisoCompartir`;
  }

  remove(id: number) {
    return `This action removes a #${id} permisoCompartir`;
  }
}

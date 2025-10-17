import { Injectable } from '@nestjs/common';
import { CreateInformeDto } from './dto/create-informe.dto';
import { UpdateInformeDto } from './dto/update-informe.dto';

@Injectable()
export class InformeService {
  create(createInformeDto: CreateInformeDto) {
    return 'This action adds a new informe';
  }

  findAll() {
    return `This action returns all informe`;
  }

  findOne(id: number) {
    return `This action returns a #${id} informe`;
  }

  update(id: number, updateInformeDto: UpdateInformeDto) {
    return `This action updates a #${id} informe`;
  }

  remove(id: number) {
    return `This action removes a #${id} informe`;
  }
}

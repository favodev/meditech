import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Institucion } from './entities/institucion.schema';
import { CreateInstitucionDto } from './dto/create-institucion.dto';
import { UpdateInstitucionDto } from './dto/update-institucion.dto';

@Injectable()
export class InstitucionService {
  constructor(
    @InjectModel(Institucion.name) private institucionModel: Model<Institucion>,
  ) {}

  async create(
    createInstitucionDto: CreateInstitucionDto,
  ): Promise<Institucion> {
    const institucion = new this.institucionModel(createInstitucionDto);
    return institucion.save();
  }

  async findAll(): Promise<Institucion[]> {
    return this.institucionModel.find().exec();
  }

  async findOne(id: string): Promise<Institucion | null> {
    return this.institucionModel.findById(id).exec();
  }

  async update(
    id: string,
    updateInstitucionDto: UpdateInstitucionDto,
  ): Promise<Institucion | null> {
    return this.institucionModel
      .findByIdAndUpdate(id, updateInstitucionDto, { new: true })
      .exec();
  }

  async remove(id: string): Promise<void> {
    await this.institucionModel.findByIdAndDelete(id).exec();
  }
}

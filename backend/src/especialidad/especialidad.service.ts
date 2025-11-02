import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CreateEspecialidadDto } from './dto/create-especialidad.dto';
import { UpdateEspecialidadDto } from './dto/update-especialidad.dto';
import { Especialidad } from './entities/especialidad.schema';

@Injectable()
export class EspecialidadService {
  constructor(
    @InjectModel(Especialidad.name)
    private especialidadModel: Model<Especialidad>,
  ) {}

  async create(
    createEspecialidadDto: CreateEspecialidadDto,
  ): Promise<Especialidad> {
    try {
      const especialidad = new this.especialidadModel(createEspecialidadDto);
      return await especialidad.save();
    } catch (error) {
      if (error.code === 11000) {
        throw new ConflictException('La especialidad ya existe');
      }
      throw error;
    }
  }

  async findAll(): Promise<Especialidad[]> {
    return await this.especialidadModel.find().exec();
  }

  async findOne(id: string): Promise<Especialidad> {
    const especialidad = await this.especialidadModel.findById(id).exec();
    if (!especialidad) {
      throw new NotFoundException(`Especialidad con id ${id} no encontrada`);
    }
    return especialidad;
  }

  async update(
    id: string,
    updateEspecialidadDto: UpdateEspecialidadDto,
  ): Promise<Especialidad> {
    try {
      const especialidad = await this.especialidadModel
        .findByIdAndUpdate(id, updateEspecialidadDto, { new: true })
        .exec();
      if (!especialidad) {
        throw new NotFoundException(`Especialidad con id ${id} no encontrada`);
      }
      return especialidad;
    } catch (error) {
      if (error.code === 11000) {
        throw new ConflictException('La especialidad ya existe');
      }
      throw error;
    }
  }

  async remove(id: string): Promise<void> {
    const result = await this.especialidadModel.findByIdAndDelete(id).exec();
    if (!result) {
      throw new NotFoundException(`Especialidad con id ${id} no encontrada`);
    }
  }
}

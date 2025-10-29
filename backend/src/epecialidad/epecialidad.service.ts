import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CreateEpecialidadDto } from './dto/create-epecialidad.dto';
import { UpdateEpecialidadDto } from './dto/update-epecialidad.dto';
import { Especialidad } from './entities/epecialidad.schema';

@Injectable()
export class EpecialidadService {
  constructor(
    @InjectModel(Especialidad.name)
    private especialidadModel: Model<Especialidad>,
  ) {}

  async create(
    createEpecialidadDto: CreateEpecialidadDto,
  ): Promise<Especialidad> {
    try {
      const especialidad = new this.especialidadModel(createEpecialidadDto);
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
    updateEpecialidadDto: UpdateEpecialidadDto,
  ): Promise<Especialidad> {
    try {
      const especialidad = await this.especialidadModel
        .findByIdAndUpdate(id, updateEpecialidadDto, { new: true })
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

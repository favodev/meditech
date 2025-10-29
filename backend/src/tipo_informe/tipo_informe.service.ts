import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CreateTipoInformeDto } from './dto/create-tipo_informe.dto';
import { UpdateTipoInformeDto } from './dto/update-tipo_informe.dto';
import { TipoInforme } from './entities/tipo_informe.schema';

@Injectable()
export class TipoInformeService {
  constructor(
    @InjectModel(TipoInforme.name) private tipoInformeModel: Model<TipoInforme>,
  ) {}

  async create(
    createTipoInformeDto: CreateTipoInformeDto,
  ): Promise<TipoInforme> {
    try {
      const tipoInforme = new this.tipoInformeModel(createTipoInformeDto);
      return await tipoInforme.save();
    } catch (error) {
      if (error.code === 11000) {
        throw new ConflictException('El tipo de informe ya existe');
      }
      throw error;
    }
  }

  async findAll(): Promise<TipoInforme[]> {
    return await this.tipoInformeModel.find().exec();
  }

  async findOne(id: string): Promise<TipoInforme> {
    const tipoInforme = await this.tipoInformeModel.findById(id).exec();
    if (!tipoInforme) {
      throw new NotFoundException(`Tipo de informe con id ${id} no encontrado`);
    }
    return tipoInforme;
  }

  async update(
    id: string,
    updateTipoInformeDto: UpdateTipoInformeDto,
  ): Promise<TipoInforme> {
    try {
      const tipoInforme = await this.tipoInformeModel
        .findByIdAndUpdate(id, updateTipoInformeDto, { new: true })
        .exec();
      if (!tipoInforme) {
        throw new NotFoundException(
          `Tipo de informe con id ${id} no encontrado`,
        );
      }
      return tipoInforme;
    } catch (error) {
      if (error.code === 11000) {
        throw new ConflictException('El tipo de informe ya existe');
      }
      throw error;
    }
  }

  async remove(id: string): Promise<void> {
    const result = await this.tipoInformeModel.findByIdAndDelete(id).exec();
    if (!result) {
      throw new NotFoundException(`Tipo de informe con id ${id} no encontrado`);
    }
  }
}

import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CreateTipoInstitucionDto } from './dto/create-tipo_institucion.dto';
import { UpdateTipoInstitucionDto } from './dto/update-tipo_institucion.dto';
import { TipoInstitucion } from './entities/tipo_institucion.schema';

@Injectable()
export class TipoInstitucionService {
  constructor(
    @InjectModel(TipoInstitucion.name)
    private tipoInstitucionModel: Model<TipoInstitucion>,
  ) {}

  async create(
    createTipoInstitucionDto: CreateTipoInstitucionDto,
  ): Promise<TipoInstitucion> {
    try {
      const tipoInstitucion = new this.tipoInstitucionModel(
        createTipoInstitucionDto,
      );
      return await tipoInstitucion.save();
    } catch (error) {
      if (error.code === 11000) {
        throw new ConflictException('El tipo de institución ya existe');
      }
      throw error;
    }
  }

  async findAll(): Promise<TipoInstitucion[]> {
    return await this.tipoInstitucionModel.find().exec();
  }

  async findOne(id: string): Promise<TipoInstitucion> {
    const tipoInstitucion = await this.tipoInstitucionModel.findById(id).exec();
    if (!tipoInstitucion) {
      throw new NotFoundException(
        `Tipo de institución con id ${id} no encontrado`,
      );
    }
    return tipoInstitucion;
  }

  async update(
    id: string,
    updateTipoInstitucionDto: UpdateTipoInstitucionDto,
  ): Promise<TipoInstitucion> {
    try {
      const tipoInstitucion = await this.tipoInstitucionModel
        .findByIdAndUpdate(id, updateTipoInstitucionDto, { new: true })
        .exec();
      if (!tipoInstitucion) {
        throw new NotFoundException(
          `Tipo de institución con id ${id} no encontrado`,
        );
      }
      return tipoInstitucion;
    } catch (error) {
      if (error.code === 11000) {
        throw new ConflictException('El tipo de institución ya existe');
      }
      throw error;
    }
  }

  async remove(id: string): Promise<void> {
    const result = await this.tipoInstitucionModel.findByIdAndDelete(id).exec();
    if (!result) {
      throw new NotFoundException(
        `Tipo de institución con id ${id} no encontrado`,
      );
    }
  }
}

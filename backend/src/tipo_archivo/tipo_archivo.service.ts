import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CreateTipoArchivoDto } from './dto/create-tipo_archivo.dto';
import { UpdateTipoArchivoDto } from './dto/update-tipo_archivo.dto';
import { TipoArchivo } from './entities/tipo_archivo.schema';

@Injectable()
export class TipoArchivoService {
  constructor(
    @InjectModel(TipoArchivo.name) private tipoArchivoModel: Model<TipoArchivo>,
  ) {}

  async create(
    createTipoArchivoDto: CreateTipoArchivoDto,
  ): Promise<TipoArchivo> {
    try {
      const tipoArchivo = new this.tipoArchivoModel(createTipoArchivoDto);
      return await tipoArchivo.save();
    } catch (error) {
      if (error.code === 11000) {
        throw new ConflictException('El tipo de archivo ya existe');
      }
      throw error;
    }
  }

  async findAll(): Promise<TipoArchivo[]> {
    return await this.tipoArchivoModel.find().exec();
  }

  async findOne(id: string): Promise<TipoArchivo> {
    const tipoArchivo = await this.tipoArchivoModel.findById(id).exec();
    if (!tipoArchivo) {
      throw new NotFoundException(`Tipo de archivo con id ${id} no encontrado`);
    }
    return tipoArchivo;
  }

  async update(
    id: string,
    updateTipoArchivoDto: UpdateTipoArchivoDto,
  ): Promise<TipoArchivo> {
    try {
      const tipoArchivo = await this.tipoArchivoModel
        .findByIdAndUpdate(id, updateTipoArchivoDto, { new: true })
        .exec();
      if (!tipoArchivo) {
        throw new NotFoundException(
          `Tipo de archivo con id ${id} no encontrado`,
        );
      }
      return tipoArchivo;
    } catch (error) {
      if (error.code === 11000) {
        throw new ConflictException('El tipo de archivo ya existe');
      }
      throw error;
    }
  }

  async remove(id: string): Promise<void> {
    const result = await this.tipoArchivoModel.findByIdAndDelete(id).exec();
    if (!result) {
      throw new NotFoundException(`Tipo de archivo con id ${id} no encontrado`);
    }
  }
}

import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { PermisoCompartir } from './entities/permiso-compartir.schema';
import { Informe } from '@informe/entities/informe.schema';
import { CreatePermisoCompartirDto } from './dto/create-permiso-compartir.dto';

@Injectable()
export class PermisoCompartirService {
  constructor(
    @InjectModel(PermisoCompartir.name)
    private permisoModel: Model<PermisoCompartir>,

    @InjectModel(Informe.name) private informeModel: Model<Informe>,
  ) {}

  async create(
    runPaciente: string,
    dto: CreatePermisoCompartirDto,
  ): Promise<PermisoCompartir> {
    const informeOriginal = await this.informeModel
      .findById(dto.informe_id_original)
      .exec();

    if (!informeOriginal) {
      throw new NotFoundException(
        `Informe con ID ${dto.informe_id_original} no encontrado.`,
      );
    }

    const informeEmbebido = {
      titulo: informeOriginal.titulo,
      tipo_informe: informeOriginal.tipo_informe,
      observaciones: informeOriginal.observaciones,
      archivos: dto.archivos ?? informeOriginal.archivos,
    };

    const nuevoPermiso = new this.permisoModel({
      nivel_acceso: dto.nivel_acceso,
      fecha_limite: dto.fecha_limite,
      run_paciente: runPaciente,
      run_medico: dto.run_medico,
      informe_id_original: dto.informe_id_original,
      informe: informeEmbebido,
    });

    return nuevoPermiso.save();
  }
}

import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { PermisoCompartir } from './entities/permiso-compartir.schema';
import { Informe } from '@informe/entities/informe.schema';
import { CreatePermisoCompartirDto } from './dto/create-permiso-compartir.dto';
import { Usuario } from '@usuario/entities/usuario.schema';

@Injectable()
export class PermisoCompartirService {
  constructor(
    @InjectModel(PermisoCompartir.name)
    private permisoModel: Model<PermisoCompartir>,

    @InjectModel(Informe.name) private informeModel: Model<Informe>,

    @InjectModel(Usuario.name) private userModel: Model<Usuario>,
  ) {}

  async createFormalAccess(
    patientRun: string,
    doctorRun: string,
    reportId: string,
    expiryDays: number,
  ): Promise<PermisoCompartir> {
    const doctor = await this.userModel.findOne({
      run: doctorRun,
      tipo_usuario: 'medico',
    });

    if (!doctor) {
      throw new NotFoundException(
        'El profesional no se encuentra registrado en el sistema',
      );
    }

    const report = await this.informeModel.findById(reportId);
    if (!report) {
      throw new NotFoundException('Informe no encontrado');
    }

    const expiration = new Date();
    expiration.setDate(expiration.getDate() + expiryDays);

    const informeEmbebido = {
      titulo: report.titulo,
      tipo_informe: report.tipo_informe,
      observaciones: report.observaciones,
      contenido_clinico: report.contenido_clinico,
      archivos: report.archivos,
    };

    return this.permisoModel.findOneAndUpdate(
      { informe_id_original: reportId, run_medico: doctorRun },
      {
        informe_id_original: reportId,
        run_paciente: patientRun,
        run_medico: doctorRun,
        nivel_acceso: 'lectura',
        fecha_limite: expiration,
        informe: informeEmbebido,
      },
      { upsert: true, new: true },
    );
  }

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
      contenido_clinico: informeOriginal.contenido_clinico,
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

  findCompartidosConMedico(runMedico: string): Promise<PermisoCompartir[]> {
    return this.permisoModel
      .find({
        run_medico: runMedico,
        fecha_limite: { $gte: new Date() },
      })
      .exec();
  }
}

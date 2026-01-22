import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Informe } from './entities/informe.schema';
import { Usuario } from '@usuario/entities/usuario.schema';

interface InformeConTimestamps {
  createdAt: Date;
  contenido_clinico?: {
    inr_actual?: number;
  };
}

@Injectable()
export class EstadisticasService {
  constructor(
    @InjectModel(Informe.name) private informeModel: Model<Informe>,
    @InjectModel(Usuario.name) private userModel: Model<Usuario>,
  ) { }

  async getResumenClinico(runPaciente: string) {
    const paciente = await this.userModel.findOne({ run: runPaciente }).exec();
    let rangoMin: number;
    let rangoMax: number;

    if (!paciente || !paciente.datos_anticoagulacion) {
      rangoMin = 2.0;
      rangoMax = 3.0;
    } else {
      rangoMin = paciente.datos_anticoagulacion.rango_meta.min;
      rangoMax = paciente.datos_anticoagulacion.rango_meta.max;
    }

    const informes = await this.informeModel
      .find({
        run_paciente: runPaciente,
        tipo_informe: 'Control de Anticoagulación',
        'contenido_clinico.inr_actual': { $exists: true },
      })
      .sort({ createdAt: 1 })
      .select('createdAt contenido_clinico.inr_actual')
      .lean<InformeConTimestamps[]>()
      .exec();

    const historial = informes
      .filter((inf) => inf.contenido_clinico?.inr_actual !== undefined)
      .map((inf) => ({
        fecha: inf.createdAt,
        inr: inf.contenido_clinico!.inr_actual!,
        estado:
          inf.contenido_clinico!.inr_actual! < rangoMin
            ? 'bajo'
            : inf.contenido_clinico!.inr_actual! > rangoMax
              ? 'alto'
              : 'meta',
      }));

    const ttr = this.calcularRosendaalTTR(historial, rangoMin, rangoMax);

    return {
      rango_meta: { min: rangoMin, max: rangoMax },
      ttr_porcentaje: ttr,
      total_controles: historial.length,
      historial_grafico: historial,
    };
  }

  private calcularRosendaalTTR(
    historial: any[],
    min: number,
    max: number,
  ): number {
    if (historial.length < 2) return 0;

    let totalDiasEvaluados = 0;
    let diasEnRango = 0;
    const LIMITE_DIAS_ROSENDAAL = 56;

    for (let i = 0; i < historial.length - 1; i++) {
      const fechaInicio = new Date(historial[i].fecha);
      const fechaFin = new Date(historial[i + 1].fecha);
      const inrInicio = historial[i].inr;
      const inrFin = historial[i + 1].inr;

      const diferenciaTiempo = fechaFin.getTime() - fechaInicio.getTime();
      const diasIntervalo = Math.ceil(diferenciaTiempo / (1000 * 60 * 60 * 24));

      if (diasIntervalo > LIMITE_DIAS_ROSENDAAL || diasIntervalo <= 0) {
        continue;
      }

      totalDiasEvaluados += diasIntervalo;
      const pendiente = (inrFin - inrInicio) / diasIntervalo;

      for (let j = 0; j < diasIntervalo; j++) {
        const inrInterpolado = inrInicio + pendiente * j;
        if (inrInterpolado >= min && inrInterpolado <= max) {
          diasEnRango++;
        }
      }
    }

    return totalDiasEvaluados === 0
      ? 0
      : parseFloat(((diasEnRango / totalDiasEvaluados) * 100).toFixed(2));
  }


  async getTtrIntervalo(runPaciente: string, inrNuevo: number, fechaNueva: Date) {
    const ultimoInforme = await this.informeModel
      .findOne({
        run_paciente: runPaciente,
        tipo_informe: 'Control de Anticoagulación',
      })
      .sort({ createdAt: -1 })
      .exec();

    if (!ultimoInforme || !ultimoInforme.contenido_clinico?.inr_actual) {
      return null;
    }

    const paciente = await this.userModel.findOne({ run: runPaciente }).exec();
    const rangoMin = paciente?.datos_anticoagulacion?.rango_meta?.min || 2.0;
    const rangoMax = paciente?.datos_anticoagulacion?.rango_meta?.max || 3.0;

    const historialIntervalo = [
      {
        fecha: ultimoInforme.createdAt,
        inr: ultimoInforme.contenido_clinico.inr_actual,
      },
      {
        fecha: fechaNueva,
        inr: inrNuevo,
      },
    ];

    return this.calcularRosendaalTTR(historialIntervalo, rangoMin, rangoMax);
  }
}


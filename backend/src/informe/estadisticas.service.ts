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
  ) {}

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

    let totalDias = 0;
    let diasEnRango = 0;

    for (let i = 0; i < historial.length - 1; i++) {
      const control1 = historial[i];
      const control2 = historial[i + 1];

      const diffTime = control2.fecha.getTime() - control1.fecha.getTime();
      const diasIntervalo = diffTime / (1000 * 3600 * 24);

      if (diasIntervalo <= 0) continue;

      const inrInicial = control1.inr;
      const inrFinal = control2.inr;

      if (
        inrInicial >= min &&
        inrInicial <= max &&
        inrFinal >= min &&
        inrFinal <= max
      ) {
        diasEnRango += diasIntervalo;
      } else if (
        (inrInicial < min && inrFinal < min) ||
        (inrInicial > max && inrFinal > max)
      ) {
        diasEnRango += 0;
      } else {
        const cambioPorDia = (inrFinal - inrInicial) / diasIntervalo;

        let inrActual = inrInicial;
        for (let d = 0; d < diasIntervalo; d++) {
          if (inrActual >= min && inrActual <= max) {
            diasEnRango += 1;
          }
          inrActual += cambioPorDia;
        }
      }

      totalDias += diasIntervalo;
    }

    if (totalDias === 0) return 0;

    return Math.round((diasEnRango / totalDias) * 100);
  }
}

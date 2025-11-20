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
    // 1. Obtener el Rango Meta del Paciente (Para saber qué es "bueno")
    const paciente = await this.userModel.findOne({ run: runPaciente }).exec();
    let rangoMin: number;
    let rangoMax: number;

    if (!paciente || !paciente.datos_anticoagulacion) {
      // Valores por defecto si no está configurado (Estándar médico)
      rangoMin = 2.0;
      rangoMax = 3.0;
    } else {
      rangoMin = paciente.datos_anticoagulacion.rango_meta.min;
      rangoMax = paciente.datos_anticoagulacion.rango_meta.max;
    }

    // 2. Buscar historial de INR (Ordenado por fecha ASCENDENTE)
    const informes = await this.informeModel
      .find({
        run_paciente: runPaciente,
        tipo_informe: 'Control de Anticoagulación', // Solo nos sirven estos
        'contenido_clinico.inr_actual': { $exists: true }, // Que tengan dato
      })
      .sort({ createdAt: 1 }) // Orden cronológico vital para Rosendaal
      .select('createdAt contenido_clinico.inr_actual') // Solo traemos lo necesario
      .lean<InformeConTimestamps[]>()
      .exec();

    // 3. Mapear a formato ligero para el gráfico
    const historial = informes
      .filter((inf) => inf.contenido_clinico?.inr_actual !== undefined)
      .map((inf) => ({
        fecha: inf.createdAt,
        inr: inf.contenido_clinico!.inr_actual!,
        // Flag visual para el frontend
        estado:
          inf.contenido_clinico!.inr_actual! < rangoMin
            ? 'bajo'
            : inf.contenido_clinico!.inr_actual! > rangoMax
              ? 'alto'
              : 'meta',
      }));

    // 4. Calcular TTR (La Nota de Calidad)
    const ttr = this.calcularRosendaalTTR(historial, rangoMin, rangoMax);

    return {
      rango_meta: { min: rangoMin, max: rangoMax },
      ttr_porcentaje: ttr,
      total_controles: historial.length,
      historial_grafico: historial,
    };
  }

  // --- ALGORITMO DE ROSENDAAL (Matemática) ---
  private calcularRosendaalTTR(
    historial: any[],
    min: number,
    max: number,
  ): number {
    if (historial.length < 2) return 0; // Necesitamos al menos 2 puntos para trazar una línea

    let totalDias = 0;
    let diasEnRango = 0;

    // Iteramos entre cada par de controles consecutivos
    for (let i = 0; i < historial.length - 1; i++) {
      const control1 = historial[i];
      const control2 = historial[i + 1];

      // Diferencia de tiempo en días
      const diffTime = control2.fecha.getTime() - control1.fecha.getTime();
      const diasIntervalo = diffTime / (1000 * 3600 * 24);

      if (diasIntervalo <= 0) continue;

      // Interpolación Lineal
      const inrInicial = control1.inr;
      const inrFinal = control2.inr;

      // Caso 1: Ambos están dentro del rango (Todo el intervalo cuenta)
      if (
        inrInicial >= min &&
        inrInicial <= max &&
        inrFinal >= min &&
        inrFinal <= max
      ) {
        diasEnRango += diasIntervalo;
      }
      // Caso 2: Ambos están fuera del mismo lado (Ningún día cuenta)
      else if (
        (inrInicial < min && inrFinal < min) ||
        (inrInicial > max && inrFinal > max)
      ) {
        diasEnRango += 0;
      }
      // Caso 3: La línea cruza el rango (Matemática de intersección)
      else {
        // Calculamos la pendiente de la línea
        const cambioPorDia = (inrFinal - inrInicial) / diasIntervalo;

        // Sumamos paso a paso (aproximación por día) para robustez
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

    // Retornamos porcentaje redondeado
    return Math.round((diasEnRango / totalDias) * 100);
  }
}

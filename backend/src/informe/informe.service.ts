import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Informe } from './entities/informe.schema';
import { CreateInformeDto } from './dto/create-informe.dto';
import { StorageService } from '@storage/storage.service';
import { Usuario } from '@modules/usuario/entities/usuario.schema';

@Injectable()
export class InformeService {
  constructor(
    @InjectModel(Informe.name) private informeModel: Model<Informe>,
    @InjectModel(Usuario.name) private userModel: Model<Usuario>,
    private readonly storageService: StorageService,
  ) {}

  findAll(run: string): Promise<Informe[]> {
    return this.informeModel.find({ run_paciente: run }).exec();
  }

  async create(
    runPaciente: string, // Recibido del controller
    runMedico: string, // Recibido del controller
    dto: CreateInformeDto,
    files?: Express.Multer.File[],
  ): Promise<Informe> {
    const informeData = new this.informeModel({
      titulo: dto.titulo,
      tipo_informe: dto.tipo_informe,
      observaciones: dto.observaciones,
      run_paciente: runPaciente,
      run_medico: runMedico,
      archivos: [],
    });

    if (dto.tipo_informe === 'Control de Anticoagulación') {
      if (!dto.contenido_clinico || !dto.contenido_clinico.dosis_diaria) {
        throw new BadRequestException(
          'Un control de TACO debe incluir INR y calendario de dosis.',
        );
      }

      // A. Calcular la Dosis Semanal Total (Mg)
      const dosisSemanalMg = await this.calcularDosisSemanal(
        runPaciente,
        dto.contenido_clinico.dosis_diaria,
      );

      // B. Asignar los datos calculados al documento
      informeData.contenido_clinico = {
        ...dto.contenido_clinico,
        dosis_semanal_total_mg: dosisSemanalMg, // <--- DATO CALCULADO
      };
    }

    if (files && files.length > 0) {
      for (const file of files) {
        const sanitizedName = file.originalname
          .toLowerCase()
          .replace(/\s+/g, '-')
          .replace(/[^a-z0-9.\-]/g, '');
        const path = await this.storageService.uploadFile(
          file,
          informeData.id,
          sanitizedName,
        );

        informeData.archivos.push({
          nombre: file.originalname,
          formato: file.mimetype,
          urlpath: path,
        });
      }
    }
    return informeData.save();
  }

  // --- MÉTODO PRIVADO: CALCULADORA DE DOSIS ---
  private async calcularDosisSemanal(
    runPaciente: string,
    calendario: any,
  ): Promise<number> {
    // 1. Buscar al paciente para saber qué pastilla toma
    const paciente = await this.userModel.findOne({ run: runPaciente }).exec();

    if (!paciente || !paciente.datos_anticoagulacion) {
      // Si no tiene configuración, asumimos el estándar de seguridad (4mg Aceno)
      // O lanzamos error obligándolo a configurarse. Por seguridad, mejor lanzamos error.
      throw new BadRequestException(
        'El paciente no tiene configurado su tratamiento de anticoagulación.',
      );
    }

    const mgBase = paciente.datos_anticoagulacion.mg_por_pastilla || 4; // Default seguro

    // 2. Sumar las fracciones
    let sumaFracciones = 0;
    const dias = [
      'lunes',
      'martes',
      'miercoles',
      'jueves',
      'viernes',
      'sabado',
      'domingo',
    ];

    for (const dia of dias) {
      const instruccion = calendario[dia]; // Ej: "1/2", "1", "1/4", "0"
      sumaFracciones += this.fraccionANumero(instruccion);
    }

    // 3. Retornar total en mg
    return sumaFracciones * mgBase;
  }

  // Helper para convertir "1/2" a 0.5
  private fraccionANumero(texto: string): number {
    if (!texto) return 0;
    const limpio = texto.trim();

    if (limpio === '1/4') return 0.25;
    if (limpio === '1/2') return 0.5;
    if (limpio === '3/4') return 0.75;
    if (limpio === '1') return 1;
    if (limpio === '0' || limpio.toLowerCase() === 'sin dosis') return 0;

    // Intento de parseo genérico por si mandan "1.5"
    const numero = parseFloat(limpio);
    return isNaN(numero) ? 0 : numero;
  }
}

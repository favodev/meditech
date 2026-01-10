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
    runPaciente: string, 
    runMedico: string, 
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

      const dosisSemanalMg = await this.calcularDosisSemanal(
        runPaciente,
        dto.contenido_clinico.dosis_diaria,
      );

      informeData.contenido_clinico = {
        ...dto.contenido_clinico,
        dosis_semanal_total_mg: dosisSemanalMg,
      };
    }

    if (files && files.length > 0) {
      const uploadPromises = files.map(async (file) => {
        const sanitizedName = file.originalname
          .toLowerCase()
          .replace(/\s+/g, '-')
          .replace(/[^a-z0-9.\-]/g, '');

        const path = await this.storageService.uploadFile(
          file,
          informeData.id,
          sanitizedName,
        );

        let tipoArchivo = 'Documento Adjunto';
        if (dto.tipo_informe === 'Control de Anticoagulación') {
          tipoArchivo = 'Resultado INR';
        }

        return {
          nombre: file.originalname,
          tipo: tipoArchivo,
          formato: file.mimetype,
          urlpath: path,
        };
      });

      const fileDetails = await Promise.all(uploadPromises);
      informeData.archivos = fileDetails;
    }

    return informeData.save();
  }

  private async calcularDosisSemanal(
    runPaciente: string,
    calendario: any,
  ): Promise<number> {
    const paciente = await this.userModel.findOne({ run: runPaciente }).exec();

    if (!paciente || !paciente.datos_anticoagulacion) {
      throw new BadRequestException(
        'El paciente no tiene configurado su tratamiento de anticoagulación.',
      );
    }

    const mgBase = paciente.datos_anticoagulacion.mg_por_pastilla || 4;

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
      const instruccion = calendario[dia];
      sumaFracciones += this.fraccionANumero(instruccion);
    }

    return sumaFracciones * mgBase;
  }

  private fraccionANumero(texto: string): number {
    if (!texto) return 0;
    const limpio = texto.trim();

    if (limpio === '1/4') return 0.25;
    if (limpio === '1/2') return 0.5;
    if (limpio === '3/4') return 0.75;
    if (limpio === '1') return 1;
    if (limpio === '0' || limpio.toLowerCase() === 'sin dosis') return 0;

    const numero = parseFloat(limpio);
    return isNaN(numero) ? 0 : numero;
  }
}

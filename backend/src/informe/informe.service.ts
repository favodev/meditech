import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Informe } from './entities/informe.schema';
import { CreateInformeDto } from './dto/create-informe.dto';
import { StorageService } from '../storage/storage.service';

@Injectable()
export class InformeService {
  constructor(
    @InjectModel(Informe.name) private informeModel: Model<Informe>,
    private readonly storageService: StorageService,
  ) {}

  async create(
    runPaciente: string,
    createInformeDto: CreateInformeDto,
    files?: Express.Multer.File[],
  ): Promise<Informe> {
    const informeData = new this.informeModel({
      titulo: createInformeDto.titulo,
      tipo_informe: createInformeDto.tipo_informe,
      observaciones: createInformeDto.observaciones,
      run_paciente: runPaciente,
      run_medico: createInformeDto.run_medico,
      archivos: [],
    });

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
}

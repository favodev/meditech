import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { v4 as uuidv4 } from 'uuid';
import { PermisoPublico } from './entities/permiso-publico.schema';
import { Informe, Archivo } from '@informe/entities/informe.schema';
import { StorageService } from '@storage/storage.service';
import { CreatePermisoPublicoDto } from './dto/create-permiso-publico.dto';
import { ConfigService } from '@nestjs/config';
import * as qrcode from 'qrcode';

@Injectable()
export class PermisoPublicoService {
  constructor(
    @InjectModel(PermisoPublico.name)
    private permisoModel: Model<PermisoPublico>,
    @InjectModel(Informe.name) private informeModel: Model<Informe>,
    private readonly storageService: StorageService,
    private readonly configService: ConfigService,
  ) {}

  async create(
    runPaciente: string,
    dto: CreatePermisoPublicoDto,
  ): Promise<{ Url: string; Qr: string; ExpirationMinutes: number }> {
    const ttlMinutes =
      Number(this.configService.get<number>('QR_EXPIRATION_MINUTES')) || 60;
    const fechaLimite = new Date(Date.now() + ttlMinutes * 60 * 1000);

    const informeOriginal = await this.informeModel
      .findById(dto.informe_id_original)
      .exec();

    if (!informeOriginal) {
      throw new NotFoundException(
        `Informe con ID ${dto.informe_id_original} no encontrado.`,
      );
    }

    if (informeOriginal.run_paciente !== runPaciente) {
      throw new ForbiddenException(
        'No tienes permiso para compartir este informe.',
      );
    }

    const token = uuidv4();

    const archivos = dto.archivos ?? informeOriginal.archivos;
    const archivosEmbebidos: Archivo[] = [];
    for (const archivoDto of archivos) {
      const signedUrl = await this.storageService.downloadFile(
        archivoDto.urlpath,
        archivoDto.nombre,
        archivoDto.formato,
        ttlMinutes,
      );

      archivosEmbebidos.push({
        nombre: archivoDto.nombre,
        formato: archivoDto.formato,
        urlpath: signedUrl,
        tipo: archivoDto.tipo,
      } as Archivo);
    }

    const informeEmbebido = {
      titulo: informeOriginal.titulo,
      tipo_informe: informeOriginal.tipo_informe,
      observaciones: informeOriginal.observaciones,
      contenido_clinico: informeOriginal.contenido_clinico,
      archivos: archivosEmbebidos,
    };

    const nuevoPermiso = new this.permisoModel({
      token: token,
      run_paciente: runPaciente,
      informe_id_original: dto.informe_id_original,
      nivel_acceso: dto.nivel_acceso,
      fecha_limite: fechaLimite,
      informe: informeEmbebido,
    });
    const baseUrl = this.configService.get('PUBLIC_VIEWER_URL');
    await nuevoPermiso.save();
    const publicUrl = `${baseUrl}?token=${token}`;

    return {
      Url: publicUrl,
      Qr: await qrcode.toDataURL(publicUrl),
      ExpirationMinutes: ttlMinutes,
    };
  }

  async getPublicInforme(token: string) {
    const permiso = await this.permisoModel.findOne({ token: token }).exec();

    if (!permiso) {
      throw new NotFoundException('El enlace de acceso no es válido.');
    }

    const ahora = new Date();
    if (ahora > permiso.fecha_limite) {
      await permiso.deleteOne();
      throw new ForbiddenException('El enlace de acceso ha expirado.');
    }

    return permiso.informe;
  }
}

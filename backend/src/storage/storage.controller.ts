import {
  Body,
  Controller,
  Post,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
  ValidationPipe,
  BadRequestException,
  InternalServerErrorException,
} from '@nestjs/common';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { AuthGuard } from '@nestjs/passport';
import { StorageService } from './storage.service';
import { getDownloadUrlDto } from './dto/get-download-url.dto';
import { getOpenUrlDto } from './dto/get-open-url.dto';

@Controller('storage')
@UseGuards(AuthGuard('jwt'))
export class StorageController {
  constructor(private readonly storageService: StorageService) {}

  @Post('upload')
  @UseInterceptors(FileFieldsInterceptor([{ name: 'file', maxCount: 1 }]))
  async uploadFile(
    @UploadedFiles() files: { file?: Express.Multer.File[] },
    @Body('destination') destination: string,
  ) {
    const file = files?.file?.[0];

    if (!file) {
      throw new BadRequestException('No se recibió ningún archivo');
    }

    if (!destination) {
      throw new BadRequestException('El campo "destination" es requerido');
    }

    const sanitizedName = file.originalname
      .toLowerCase()
      .replace(/\s+/g, '-')
      .replace(/[^a-z0-9.\-]/g, '');

    const path = await this.storageService.uploadFile(
      file,
      destination,
      sanitizedName,
    );

    return {
      message: 'Archivo subido exitosamente',
      path,
      originalName: file.originalname,
      size: file.size,
    };
  }

  @Post('get-download-url')
  async getDownloadUrl(
    @Body(ValidationPipe) getDownloadUrlDto: getDownloadUrlDto,
  ) {
    const { path, name, format } = getDownloadUrlDto;

    const signedUrl = await this.storageService.downloadFile(
      path,
      name,
      format,
      30,
    );

    return {
      signedUrl,
      expiresInMinutes: 30,
    };
  }

  @Post('get-open-url')
  async getOpenUrl(@Body(ValidationPipe) getOpenUrlDto: getOpenUrlDto) {
    const { path } = getOpenUrlDto;

    const signedUrl = await this.storageService.openFile(path, 30);

    return {
      signedUrl,
      expiresInMinutes: 30,
    };
  }
}

import {
  Body,
  Controller,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
  ValidationPipe,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AuthGuard } from '@nestjs/passport';
import { StorageService } from './storage.service';
import { getDownloadUrlDto } from './dto/get-download-url.dto';
import { getOpenUrlDto } from './dto/get-open-url.dto';

@Controller('storage')
@UseGuards(AuthGuard('jwt'))
export class StorageController {
  constructor(private readonly storageService: StorageService) {}

  @Post('upload')
  @UseInterceptors(FileInterceptor('file'))
  async uploadFile(
    @UploadedFile() file: Express.Multer.File,
    @Body('destination') destination: string,
  ) {
    const fileName = `${Date.now()}-${file.originalname}`;
    const fullPath = `${destination}/${fileName}`;

    const url = await this.storageService.uploadFile(file, fullPath);

    return { url, fileName };
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

    return { signedUrl };
  }

  @Post('get-open-url')
  async getOpenUrl(@Body(ValidationPipe) getOpenUrlDto: getOpenUrlDto) {
    const { path } = getOpenUrlDto;

    const signedUrl = await this.storageService.openFile(path, 30);

    return { signedUrl };
  }
}

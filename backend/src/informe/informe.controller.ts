import {
  Controller,
  Post,
  Body,
  UseGuards,
  Request,
  UploadedFiles,
  UseInterceptors,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { InformeService } from './informe.service';
import { CreateInformeDto } from './dto/create-informe.dto';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';

@Controller('informe')
@UseGuards(AuthGuard('jwt'))
export class InformeController {
  constructor(private readonly informeService: InformeService) {}

  @Post()
  @UseInterceptors(FileFieldsInterceptor([{ name: 'files', maxCount: 10 }]))
  async create(
    @Request() req,
    @UploadedFiles() files: { files?: Express.Multer.File[] },
    @Body('data') data: any,
  ) {
    const parseData = JSON.parse(data);
    const informeDto = plainToInstance(CreateInformeDto, parseData);
    const errors = await validate(informeDto);

    if (errors.length > 0) {
      return {
        message: errors[0].constraints,
        error: 'Validation failed',
        statusCode: 400,
      };
    }
    return this.informeService.create(req.user.run, informeDto, files.files);
  }
}

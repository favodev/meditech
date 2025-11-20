import {
  Controller,
  Post,
  Body,
  UseGuards,
  Request,
  UploadedFiles,
  UseInterceptors,
  Get,
  BadRequestException,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { InformeService } from './informe.service';
import { CreateInformeDto } from './dto/create-informe.dto';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { TipoUsuario } from '@enums/tipo_usuario.enum';

@Controller('informe')
@UseGuards(AuthGuard('jwt'))
export class InformeController {
  constructor(private readonly informeService: InformeService) {}

  @Get()
  async findAll(@Request() req) {
    return this.informeService.findAll(req.user.run);
  }

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

    const usuario = req.user;
    let runPacienteFinal: string;
    let runMedicoFinal: string;

    if (usuario.tipo_usuario === TipoUsuario.PACIENTE) {
      // CASO 1: Soy PACIENTE
      // El dueño soy yo (Token)
      runPacienteFinal = usuario.run;

      // El otro es el médico (DTO)
      if (!informeDto.run_medico) {
        throw new BadRequestException(
          'Si eres paciente, debes indicar el RUN del médico.',
        );
      }

      runMedicoFinal = informeDto.run_medico;
    } else if (usuario.tipo_usuario === TipoUsuario.MEDICO) {
      // CASO 2: Soy MÉDICO
      // El dueño es el otro (DTO)
      if (!informeDto.run_paciente) {
        throw new BadRequestException(
          'Si eres médico, debes indicar el RUN del paciente.',
        );
      }
      runPacienteFinal = informeDto.run_paciente;

      // El médico soy yo (Token)
      runMedicoFinal = usuario.run;
    } else {
      throw new BadRequestException(
        'Tipo de usuario no autorizado para crear informes.',
      );
    }

    return this.informeService.create(
      runPacienteFinal,
      runMedicoFinal,
      informeDto,
      files.files,
    );
  }
}

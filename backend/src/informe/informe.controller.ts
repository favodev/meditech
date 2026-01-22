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
import { EstadisticasService } from './estadisticas.service';

@Controller('informe')
@UseGuards(AuthGuard('jwt'))
export class InformeController {
  constructor(
    private readonly informeService: InformeService,
    private readonly estadisticasService: EstadisticasService,
  ) { }

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
      runPacienteFinal = usuario.run;

      if (!informeDto.run_medico) {
        throw new BadRequestException(
          'Si eres paciente, debes indicar el RUN del médico.',
        );
      }

      runMedicoFinal = informeDto.run_medico;
    } else if (usuario.tipo_usuario === TipoUsuario.MEDICO) {
      if (!informeDto.run_paciente) {
        throw new BadRequestException(
          'Si eres médico, debes indicar el RUN del paciente.',
        );
      }
      runPacienteFinal = informeDto.run_paciente;

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

  @Get('estadisticas')
  async getEstadisticas(@Request() req) {
    return this.estadisticasService.getResumenClinico(req.user.run);
  }

  @Post('calcular-intervalo')
  async calcularTtrIntervalo(@Request() req, @Body() body: any) {
    const inrActual = body.inr_actual;

    if (inrActual === undefined) {
      throw new BadRequestException('El valor de inr_actual es requerido.');
    }

    const runPaciente = req.user.tipo_usuario === TipoUsuario.PACIENTE
      ? req.user.run
      : body.run_paciente;

    if (!runPaciente) {
      throw new BadRequestException('RUN del paciente no especificado.');
    }

    const fechaActual = new Date();

    const ttrIntervalo = await this.estadisticasService.getTtrIntervalo(
      runPaciente,
      inrActual,
      fechaActual,
    );

    return {
      ttr_intervalo: ttrIntervalo,
      mensaje: ttrIntervalo === null
        ? 'No existe un control anterior para calcular el intervalo.'
        : 'Cálculo de tramo realizado con éxito.'
    };
  }
}

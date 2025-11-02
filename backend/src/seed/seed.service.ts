import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { Especialidad } from '@especialidad/entities/especialidad.schema';
import { TipoArchivo } from '@tipo_archivo/entities/tipo_archivo.schema';
import { TipoInforme } from '@tipo_informe/entities/tipo_informe.schema';
import { TipoInstitucion } from '@tipo_institucion/entities/tipo_institucion.schema';
import { Institucion } from '@institucion/entities/institucion.schema';
import { Usuario } from '@usuario/entities/usuario.schema';
import { Informe } from '@informe/entities/informe.schema';

@Injectable()
export class SeedService {
  constructor(
    @InjectModel(Especialidad.name)
    private especialidadModel: Model<Especialidad>,
    @InjectModel(TipoArchivo.name)
    private tipoArchivoModel: Model<TipoArchivo>,
    @InjectModel(TipoInforme.name)
    private tipoInformeModel: Model<TipoInforme>,
    @InjectModel(TipoInstitucion.name)
    private tipoInstitucionModel: Model<TipoInstitucion>,
    @InjectModel(Institucion.name)
    private institucionModel: Model<Institucion>,
    @InjectModel(Usuario.name)
    private usuarioModel: Model<Usuario>,
    @InjectModel(Informe.name)
    private informeModel: Model<Informe>,
  ) {}

  async seedDataBase() {
    await Promise.all([
      this.especialidadModel.deleteMany({}),
      this.tipoArchivoModel.deleteMany({}),
      this.tipoInformeModel.deleteMany({}),
      this.tipoInstitucionModel.deleteMany({}),
      this.institucionModel.deleteMany({}),
      this.usuarioModel.deleteMany({}),
      this.informeModel.deleteMany({}),
    ]);

    // Seed Especialidades (con tildes corregidas)
    const especialidades = [
      'Cardiología',
      'Dermatología',
      'Pediatría',
      'Oftalmología',
      'Neurología',
      'Traumatología',
      'Gastroenterología',
      'Neumología',
      'Endocrinología',
      'Nefrología',
      'Otorrinolaringología',
      'Psiquiatría',
      'Urología',
      'Ginecología',
      'Anestesiología',
      'Radiología',
      'Oncología',
      'Hematología',
      'Reumatología',
      'Medicina Interna',
      'Medicina Familiar',
      'Medicina de Urgencias',
      'Alergología',
      'Medicina Física y Rehabilitación',
      'Cirugía General',
      'Cirugía Plástica',
      'Cirugía Cardiovascular',
      'Cirugía Pediátrica',
      'Medicina de Cuidados Paliativos',
      'Geriatría',
      'Infectología',
      'Patología',
      'Medicina del Deporte',
      'Medicina Nuclear',
      'Genética Médica',
      'Epidemiología',
      'Salud Pública',
      'Medicina del Trabajo',
      'Fisioterapia',
      'Nutriología',
      'Odontología',
      'Psicología Clínica',
      'Podología',
      'Microbiología',
      'Bioquímica Clínica',
      'Toxicología',
      'Farmacología Clínica',
      'Inmunología Clínica',
      'Angiología',
      'Neurocirugía',
    ];

    // Seed Tipos de Archivo (con tildes corregidas)
    const tiposArchivo = [
      'Examen de Laboratorio',
      'Examen de Imagenología',
      'Receta Médica',
      'Informe Médico',
      'Interconsulta o Derivación',
      'Epicrisis o Informe de Alta',
      'Licencia Médica',
      'Consentimiento Informado',
      'Certificado de Vacunación',
    ];

    // Seed Tipos de Informe (con tildes corregidas)
    const tiposInforme = [
      'Consulta General',
      'Consulta de Especialidad',
      'Atención de Urgencia',
      'Procedimiento Médico',
      'Hospitalización',
      'Teleconsulta',
      'Entrega de Resultados',
      'Control o Seguimiento',
    ];

    // Seed Tipos de Institución (con tildes corregidas)
    const tiposInstitucion = [
      'Hospital Público',
      'CESFAM',
      'CECOSF',
      'Posta Rural',
      'SAPU',
      'SAR',
      'COSAM',
      'CDT',
      'CRS',
      'Consultorio de Especialidades',
      'Clínica',
      'Consultorio Privado',
      'Centro Médico',
      'Laboratorio',
      'Banco de Sangre',
      'Centro de Imagenología',
      'Farmacia',
      'Hogar de Ancianos',
      'Instituto de Salud Pública',
      'Instituciones Fuerzas Armadas',
      'Mutuo de Seguridad',
      'Central de Abastecimiento',
    ];

    // Seed Instituciones (hospitales, clínicas, centros médicos, etc.)
    const instituciones = [
      {
        nombre: 'Hospital Dr. Sotero del Rio',
        tipo_institucion: 'Hospital Público',
      },
      { nombre: 'Hospital del Salvador', tipo_institucion: 'Hospital Público' },
      {
        nombre: 'Hospital Regional de Antofagasta',
        tipo_institucion: 'Hospital Público',
      },
      {
        nombre: 'Hospital Clinico San Borja Arriaran',
        tipo_institucion: 'Hospital Público',
      },
      {
        nombre: 'Hospital Clinico de la Universidad de Chile',
        tipo_institucion: 'Hospital Público',
      },
      {
        nombre: 'Hospital Base de Valdivia',
        tipo_institucion: 'Hospital Público',
      },
      {
        nombre: 'Hospital Guillermo Grant Benavente',
        tipo_institucion: 'Hospital Público',
      },
      {
        nombre: 'Hospital Clinico de Magallanes',
        tipo_institucion: 'Hospital Público',
      },
      { nombre: 'Hospital de Chillan', tipo_institucion: 'Hospital Público' },
      {
        nombre: 'Hospital Regional de Concepcion',
        tipo_institucion: 'Hospital Público',
      },
      { nombre: 'Hospital de Talca', tipo_institucion: 'Hospital Público' },
      {
        nombre: 'Hospital San Juan de Dios',
        tipo_institucion: 'Hospital Público',
      },
      {
        nombre: 'Hospital de La Florida Dra. Eloisa Diaz',
        tipo_institucion: 'Hospital Público',
      },
      { nombre: 'Hospital de Melipilla', tipo_institucion: 'Hospital Público' },
      {
        nombre: 'Hospital de Puerto Montt',
        tipo_institucion: 'Hospital Público',
      },
      { nombre: 'Hospital de Coyhaique', tipo_institucion: 'Hospital Público' },
      {
        nombre: 'Hospital Regional Punta Arenas',
        tipo_institucion: 'Hospital Público',
      },
      { nombre: 'Clinica Alemana de Santiago', tipo_institucion: 'Clínica' },
      { nombre: 'Clinica Indisa', tipo_institucion: 'Clínica' },
      { nombre: 'Clinica Las Condes', tipo_institucion: 'Clínica' },
      { nombre: 'Clinica Santa Maria', tipo_institucion: 'Clínica' },
      {
        nombre: 'Clinica UC San Carlos de Apoquindo',
        tipo_institucion: 'Clínica',
      },
      {
        nombre: 'Clinica Sanatorio Aleman de Concepcion',
        tipo_institucion: 'Clínica',
      },
      { nombre: 'Clinica Bupa Santiago', tipo_institucion: 'Clínica' },
      { nombre: 'Clinica Bio Bio', tipo_institucion: 'Clínica' },
      { nombre: 'Clinica Tabancura', tipo_institucion: 'Clínica' },
      { nombre: 'Clinica Davila Vespucio', tipo_institucion: 'Clínica' },
      { nombre: 'Clinica RedSalud Santiago', tipo_institucion: 'Clínica' },
      { nombre: 'Clinica Pasteur', tipo_institucion: 'Clínica' },
      { nombre: 'Clinica Hospital del Profesor', tipo_institucion: 'Clínica' },
      { nombre: 'Clinica Bupa Renaca', tipo_institucion: 'Clínica' },
      { nombre: 'Clinica Andes Salud Concepcion', tipo_institucion: 'Clínica' },
      {
        nombre: 'Clinica Central Mutuo de Seguridad',
        tipo_institucion: 'Mutuo de Seguridad',
      },
      {
        nombre: 'Hospital del Trabajador Achs',
        tipo_institucion: 'Mutuo de Seguridad',
      },
      {
        nombre: 'CESFAM Dr. Anibal Ariztiia (Las Condes)',
        tipo_institucion: 'CESFAM',
      },
      { nombre: 'CESFAM San Rafael (La Pintana)', tipo_institucion: 'CESFAM' },
      { nombre: 'CESFAM Dr. Hector Garcia', tipo_institucion: 'CESFAM' },
      { nombre: 'CESFAM La Palmilla (Conchali)', tipo_institucion: 'CESFAM' },
      { nombre: 'CESFAM Lo Hermida (Penalolen)', tipo_institucion: 'CESFAM' },
      { nombre: 'CESFAM Padre Hurtado (Maipu)', tipo_institucion: 'CESFAM' },
      { nombre: 'CESFAM Quilicura', tipo_institucion: 'CESFAM' },
      { nombre: 'CESFAM Quinta Normal', tipo_institucion: 'CESFAM' },
      { nombre: 'CESFAM Juan Pablo II', tipo_institucion: 'CESFAM' },
      { nombre: 'CESFAM Valle de la Luna', tipo_institucion: 'CESFAM' },
      { nombre: 'CESFAM Petorca', tipo_institucion: 'CESFAM' },
      { nombre: 'CESFAM San Antonio', tipo_institucion: 'CESFAM' },
      { nombre: 'CESFAM Hualane', tipo_institucion: 'CESFAM' },
      { nombre: 'CECOSF El Bollenar', tipo_institucion: 'CECOSF' },
      { nombre: 'CECOSF Los Cerrillos', tipo_institucion: 'CECOSF' },
      { nombre: 'CECOSF Lo Canas', tipo_institucion: 'CECOSF' },
      { nombre: 'Posta Rural de Colina', tipo_institucion: 'Posta Rural' },
      {
        nombre: 'Posta Rural de San Jose de Maipo',
        tipo_institucion: 'Posta Rural',
      },
      { nombre: 'Posta Rural de Lonquen', tipo_institucion: 'Posta Rural' },
      { nombre: 'SAPU La Pintana', tipo_institucion: 'SAPU' },
      { nombre: 'SAPU El Bosque', tipo_institucion: 'SAPU' },
      { nombre: 'SAR Valdivia', tipo_institucion: 'SAR' },
      { nombre: 'SAR Osorno', tipo_institucion: 'SAR' },
      { nombre: 'COSAM Pedro Aguirre Cerda', tipo_institucion: 'COSAM' },
      { nombre: 'COSAM Recoleta', tipo_institucion: 'COSAM' },
      { nombre: 'CDT Hospital de Talca', tipo_institucion: 'CDT' },
      {
        nombre: 'CDT Hospital Clinico San Borja Arriaran',
        tipo_institucion: 'CDT',
      },
      { nombre: 'CRS Maipu', tipo_institucion: 'CRS' },
      { nombre: 'CRS Cordillera Oriente', tipo_institucion: 'CRS' },
      {
        nombre: 'Consultorio Privado Las Tranqueras',
        tipo_institucion: 'Consultorio Privado',
      },
      {
        nombre: 'Consultorio Privado Providencia',
        tipo_institucion: 'Consultorio Privado',
      },
      {
        nombre: 'Centro Medico San Joaquin',
        tipo_institucion: 'Centro Médico',
      },
      {
        nombre: 'Centro Medico Integramedica',
        tipo_institucion: 'Centro Médico',
      },
      { nombre: 'Centro Medico Megasalud', tipo_institucion: 'Centro Médico' },
      {
        nombre: 'Hospital Militar de Santiago',
        tipo_institucion: 'Instituciones Fuerzas Armadas',
      },
      {
        nombre: 'Hospital Naval Almirante Nef',
        tipo_institucion: 'Instituciones Fuerzas Armadas',
      },
      {
        nombre: 'Hospital FACH',
        tipo_institucion: 'Instituciones Fuerzas Armadas',
      },
      {
        nombre: 'Hospital Dipreca',
        tipo_institucion: 'Instituciones Fuerzas Armadas',
      },
      {
        nombre: 'Banco de Sangre del Clinico UC',
        tipo_institucion: 'Banco de Sangre',
      },
      {
        nombre: 'Banco de Sangre del Hospital San Juan de Dios',
        tipo_institucion: 'Banco de Sangre',
      },
      { nombre: 'Laboratorio Clinico Bionet', tipo_institucion: 'Laboratorio' },
      {
        nombre: 'Laboratorio Clinico Biocare',
        tipo_institucion: 'Laboratorio',
      },
      {
        nombre: 'Laboratorio Clinico Etcheverry',
        tipo_institucion: 'Laboratorio',
      },
      {
        nombre: 'Laboratorio Clinico Clinica Alemana',
        tipo_institucion: 'Laboratorio',
      },
      {
        nombre: 'Centro de Imagenologia San Joaquin',
        tipo_institucion: 'Centro de Imagenología',
      },
      {
        nombre: 'Centro de Imagenologia Clinica Indisa',
        tipo_institucion: 'Centro de Imagenología',
      },
      {
        nombre: 'Farmacia Ahumada Sucursal Providencia',
        tipo_institucion: 'Farmacia',
      },
      {
        nombre: 'Farmacia Cruz Verde Sucursal La Florida',
        tipo_institucion: 'Farmacia',
      },
      {
        nombre: 'Farmacia Salcobrand Sucursal Santiago Centro',
        tipo_institucion: 'Farmacia',
      },
      {
        nombre: 'Hogar de Ancianos Senama Las Condes',
        tipo_institucion: 'Hogar de Ancianos',
      },
      {
        nombre: 'Hogar de Ancianos Fundacion Las Rosas',
        tipo_institucion: 'Hogar de Ancianos',
      },
      {
        nombre: 'Instituto de Salud Publica ISP',
        tipo_institucion: 'Instituto de Salud Pública',
      },
      {
        nombre: 'Instituto Nacional del Cancer',
        tipo_institucion: 'Instituto de Salud Pública',
      },
      {
        nombre: 'Instituto Traumatologico',
        tipo_institucion: 'Instituto de Salud Pública',
      },
      { nombre: 'CENABAST', tipo_institucion: 'Central de Abastecimiento' },
      {
        nombre: 'Centro Medico y Dental RedSalud',
        tipo_institucion: 'Centro Médico',
      },
      { nombre: 'Centro Medico Las Lilas', tipo_institucion: 'Centro Médico' },
      {
        nombre: 'Centro Medico Clinica Andes Salud Chillan',
        tipo_institucion: 'Centro Médico',
      },
      {
        nombre: 'CESFAM Los Volcanes (Huechuraba)',
        tipo_institucion: 'CESFAM',
      },
      {
        nombre: 'CESFAM Dr. Federico Puga (Penalolen)',
        tipo_institucion: 'CESFAM',
      },
      { nombre: 'CESFAM Las Mercedes (La Serena)', tipo_institucion: 'CESFAM' },
      {
        nombre: 'CESFAM Padre Alberto Hurtado (Renca)',
        tipo_institucion: 'CESFAM',
      },
      {
        nombre: 'Clinica Andes Salud Puerto Montt',
        tipo_institucion: 'Clínica',
      },
      { nombre: 'Clinica Alemana de Valdivia', tipo_institucion: 'Clínica' },
      {
        nombre: 'Clinica San Carlos de Apoquindo',
        tipo_institucion: 'Clínica',
      },
      {
        nombre: 'Laboratorio Clinico Recoleta',
        tipo_institucion: 'Laboratorio',
      },
      {
        nombre: 'Laboratorio Clinico RedSalud',
        tipo_institucion: 'Laboratorio',
      },
      {
        nombre: 'Consultorio de Especialidades Hospital Dr. Sotero del Rio',
        tipo_institucion: 'Consultorio de Especialidades',
      },
      {
        nombre: 'Consultorio de Especialidades Hospital del Salvador',
        tipo_institucion: 'Consultorio de Especialidades',
      },
      {
        nombre: 'Hospital Comunitario de Tiltil',
        tipo_institucion: 'Hospital Público',
      },
      { nombre: 'Hospital de Lampa', tipo_institucion: 'Hospital Público' },
      { nombre: 'Hospital de Molina', tipo_institucion: 'Hospital Público' },
      { nombre: 'Hospital de Loncoche', tipo_institucion: 'Hospital Público' },
      {
        nombre: 'Hospital de Panguipulli',
        tipo_institucion: 'Hospital Público',
      },
      { nombre: 'Hospital de Osorno', tipo_institucion: 'Hospital Público' },
      { nombre: 'Clinica San Vicente de Paul', tipo_institucion: 'Clínica' },
      { nombre: 'Clinica Ciudad del Mar', tipo_institucion: 'Clínica' },
      { nombre: 'Hospital de Curacavi', tipo_institucion: 'Hospital Público' },
    ];

    // Insertar todos los datos
    const [
      especialidadesCreadas,
      tiposArchivoCreados,
      tiposInformeCreados,
      tiposInstitucionCreados,
      institucionesCreadas,
    ] = await Promise.all([
      this.especialidadModel.insertMany(
        especialidades.map((nombre) => ({ nombre })),
      ),
      this.tipoArchivoModel.insertMany(
        tiposArchivo.map((nombre) => ({ nombre })),
      ),
      this.tipoInformeModel.insertMany(
        tiposInforme.map((nombre) => ({ nombre })),
      ),
      this.tipoInstitucionModel.insertMany(
        tiposInstitucion.map((nombre) => ({ nombre })),
      ),
      this.institucionModel.insertMany(instituciones),
    ]);

    // Crear usuarios de prueba
    const passwordHash = await bcrypt.hash('password123', 10);
    const usuario1 = new this.usuarioModel({
      tipo_usuario: 'Paciente',
      nombre: 'Johnson',
      apellido: 'Valenzuela',
      email: 'johnsondavisv4@example.com',
      telefono: '+56912345678',
      password_hash: passwordHash,
      run: '20.886.732-6',
    });

    Object.assign(usuario1, {
      sexo: 'Masculino',
      direccion: 'Calle Arturo Prat S/N, Ñuble, Chile',
      fecha_nacimiento: new Date('2002-07-27'),
      telefono_emergencia: '+56987654321',
    });

    const usuario2 = new this.usuarioModel({
      tipo_usuario: 'Paciente',
      nombre: 'Fernando',
      apellido: 'Vergara',
      email: 'fernando.aurelio.vergara.ortiz@gmail.com',
      telefono: '+56956495423',
      password_hash:
        '$2b$10$Mj.y4eo48upd8LEXKB4y6e6eZNHK.YUK2kCMjSzoW53zpg4Jl4D4u',
      run: '21263713-0',
    });

    Object.assign(usuario2, {
      sexo: 'Masculino',
      direccion: 'Independencia 1148',
      fecha_nacimiento: new Date('2003-02-05T03:00:00.000Z'),
      telefono_emergencia: '+56956495423',
    });

    const usuario3 = new this.usuarioModel({
      tipo_usuario: 'Paciente',
      nombre: 'favo',
      apellido: 'second',
      email: 'kyunimexxx@gmail.com',
      telefono: '+56999999999',
      password_hash:
        '$2b$10$eWl7o045Pmqb7tMnBQhk7eoI/2rznW6NlqaS/puPYDCdJXHfNgLy.',
      run: '12762554-9',
    });

    Object.assign(usuario3, {
      sexo: 'Masculino',
      direccion: 'independencia, 1148',
      fecha_nacimiento: new Date('2003-02-05T03:00:00.000Z'),
      telefono_emergencia: '+56999999999',
    });

    await Promise.all([usuario1.save(), usuario2.save(), usuario3.save()]);

    // Crear informes de prueba
    const informe1 = new this.informeModel({
      _id: '6904fb1ede6d2dd2ff3391ad',
      titulo: 'Test',
      tipo_informe: 'Consulta de Especialidad',
      observaciones: 'aaa',
      run_paciente: '21263713-0',
      run_medico: '12762554-9',
      archivos: [
        {
          nombre: 'IMG_20251024_193618.jpg',
          formato: 'image/jpeg',
          urlpath:
            '6904fb1ede6d2dd2ff3391ad/1761934110638-img20251024193618.jpg',
        },
      ],
      createdAt: new Date('2025-10-31T18:08:32.292Z'),
      updatedAt: new Date('2025-10-31T18:08:32.292Z'),
    });

    const informe2 = new this.informeModel({
      _id: '6907e69a1707c4b4f62fdb2e',
      titulo: 'Testing2',
      tipo_informe: 'Procedimiento Médico',
      observaciones: 'nota..',
      run_paciente: '21263713-0',
      run_medico: '12762554-9',
      archivos: [
        {
          nombre: 'IMG_20251024_193618 (2).jpg',
          formato: 'image/jpeg',
          urlpath:
            '6907e69a1707c4b4f62fdb2e/1762125466038-img20251024193618-2.jpg',
        },
      ],
      createdAt: new Date('2025-11-02T23:17:47.556Z'),
      updatedAt: new Date('2025-11-02T23:17:47.556Z'),
    });

    const informe3 = new this.informeModel({
      titulo: 'Informe de Prueba',
      tipo_informe: 'Consulta General',
      observaciones: 'Paciente refiere buen estado general.',
      run_paciente: usuario1.run,
      run_medico: '9.876.543-K',
      archivos: [],
    });

    await Promise.all([informe1.save(), informe2.save(), informe3.save()]);

    return {
      message: 'Base de datos poblada exitosamente',
      data: {
        especialidades: especialidadesCreadas.length,
        tiposArchivo: tiposArchivoCreados.length,
        tiposInforme: tiposInformeCreados.length,
        tiposInstitucion: tiposInstitucionCreados.length,
        instituciones: institucionesCreadas.length,
        usuarios: 3,
        informes: 3,
      },
      usuariosPrueba: [
        {
          email: usuario1.email,
          run: usuario1.run,
          nombre: usuario1.nombre,
          password: 'password123',
        },
        {
          email: usuario2.email,
          run: usuario2.run,
          nombre: usuario2.nombre,
          password: 'fernando123',
        },
        {
          email: usuario3.email,
          run: usuario3.run,
          nombre: usuario3.nombre,
          password: 'favo123',
        },
      ],
      informesPrueba: [
        {
          id: informe1._id,
          titulo: informe1.titulo,
        },
        {
          id: informe2._id,
          titulo: informe2.titulo,
        },
        {
          id: informe3._id,
          titulo: informe3.titulo,
        },
      ],
    };
  }
}

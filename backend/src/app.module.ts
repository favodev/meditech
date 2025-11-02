import { Module } from '@nestjs/common';
import { DatabaseModule } from '@modules/database/database.module';
import { UsuarioModule } from '@modules/usuario/usuario.module';
import { InstitucionModule } from '@modules/institucion/institucion.module';
import { AuthModule } from '@auth/auth.module';
import { ConfigModule } from '@nestjs/config';
import { InformeModule } from '@modules/informe/informe.module';
import { PermisoCompartirModule } from '@modules/permiso-compartir/permiso-compartir.module';
import { StorageModule } from '@modules/storage/storage.module';
import { SeedModule } from '@modules/seed/seed.module';
import { EspecialidadModule } from '@modules/especialidad/especialidad.module';
import { TipoArchivoModule } from '@modules/tipo_archivo/tipo_archivo.module';
import { TipoInformeModule } from '@modules/tipo_informe/tipo_informe.module';
import { TipoInstitucionModule } from '@modules/tipo_institucion/tipo_institucion.module';
import { PermisoPublicoModule } from './permiso-publico/permiso-publico.module';

@Module({
  imports: [
    DatabaseModule,
    UsuarioModule,
    InstitucionModule,
    AuthModule,
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    InformeModule,
    PermisoCompartirModule,
    StorageModule,
    SeedModule,
    EspecialidadModule,
    TipoArchivoModule,
    TipoInformeModule,
    TipoInstitucionModule,
    PermisoPublicoModule,
  ],
})
export class AppModule {}

import { Module } from '@nestjs/common';
import { DatabaseModule } from '@database/database.module';
import { UsuarioModule } from '@usuario/usuario.module';
import { InstitucionModule } from '@institucion/institucion.module';
import { AuthModule } from '@auth/auth.module';
import { ConfigModule } from '@nestjs/config';
import { InformeModule } from '@informe/informe.module';
import { PermisoCompartirModule } from '@permiso-compartir/permiso-compartir.module';
import { StorageModule } from '@storage/storage.module';
import { SeedModule } from '@seed/seed.module';
import { EspecialidadModule } from '@especialidad/especialidad.module';
import { TipoArchivoModule } from '@tipo_archivo/tipo_archivo.module';
import { TipoInformeModule } from '@tipo_informe/tipo_informe.module';
import { TipoInstitucionModule } from '@tipo_institucion/tipo_institucion.module';
import { PermisoPublicoModule } from '@permiso-publico/permiso-publico.module';

@Module({
  imports: [
    DatabaseModule,
    UsuarioModule,
    InstitucionModule,
    AuthModule,
    InformeModule,
    PermisoCompartirModule,
    StorageModule,
    SeedModule,
    EspecialidadModule,
    TipoArchivoModule,
    TipoInformeModule,
    TipoInstitucionModule,
    PermisoPublicoModule,
    ConfigModule.forRoot({
      isGlobal: true,
    }),
  ],
})
export class AppModule {}

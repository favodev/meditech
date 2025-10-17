import { Module } from '@nestjs/common';
import { DatabaseModule } from './database/database.module';
import { UsuarioModule } from './usuario/usuario.module';
import { InstitucionModule } from './institucion/institucion.module';
import { AuthModule } from './auth/auth.module';
import { ConfigModule } from '@nestjs/config';
import { MedicamentoModule } from './medicamento/medicamento.module';
import { InformeModule } from './informe/informe.module';
import { PermisoCompartirModule } from './permiso-compartir/permiso-compartir.module';
import { StorageModule } from './storage/storage.module';

@Module({
  imports: [
    DatabaseModule,
    UsuarioModule,
    InstitucionModule,
    AuthModule,
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    MedicamentoModule,
    InformeModule,
    PermisoCompartirModule,
    StorageModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}

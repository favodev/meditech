import { Module } from '@nestjs/common';
import { DatabaseModule } from '@modules/database/database.module';
import { UsuarioModule } from '@modules/usuario/usuario.module';
import { InstitucionModule } from '@modules/institucion/institucion.module';
import { AuthModule } from '@auth/auth.module';
import { ConfigModule } from '@nestjs/config';
import { InformeModule } from '@modules/informe/informe.module';
import { PermisoCompartirModule } from '@modules/permiso-compartir/permiso-compartir.module';
import { StorageModule } from '@modules/storage/storage.module';

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
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}

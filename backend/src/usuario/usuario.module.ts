import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { DatabaseModule } from '../database/database.module';
import { UsuarioService } from './usuario.service';
import { UsuarioController } from './usuario.controller';
import { Usuario, UsuarioSchema } from './entities/usuario.schema';

@Module({
  imports: [
    DatabaseModule,
    MongooseModule.forFeature([{ name: Usuario.name, schema: UsuarioSchema }]),
  ],
  controllers: [UsuarioController],
  providers: [UsuarioService],
  exports: [UsuarioService, MongooseModule],
})
export class UsuarioModule {}

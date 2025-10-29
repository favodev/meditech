import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { TipoUsuario } from '@enums/tipo_usuario.enum';
import { Sexo } from '@enums/sexo.enum';

@Schema({ _id: false })
class InstitucionEmbebida {
  @Prop({ required: true })
  nombre: string;
  @Prop({ required: true })
  tipo_institucion: string;
}

const InstitucionEmbebidaSchema =
  SchemaFactory.createForClass(InstitucionEmbebida);

@Schema({ collection: 'usuarios' })
export class Usuario extends Document {
  @Prop({
    type: String,
    enum: Object.values(TipoUsuario),
    required: true,
    index: true,
  })
  tipo_usuario: string;

  @Prop({ required: true })
  nombre: string;

  @Prop({ required: true })
  apellido: string;

  @Prop({ required: true, unique: true })
  email: string;

  @Prop()
  telefono: string;

  @Prop({ required: true })
  password_hash: string;

  @Prop({ required: true, unique: true })
  run: string;

  @Prop({ type: String, required: false })
  currentHashedRefreshToken?: string;

  @Prop({ type: String, enum: Object.values(Sexo), required: false })
  sexo?: string;

  @Prop({ required: false })
  direccion?: string;

  @Prop({ required: false })
  fecha_nacimiento?: Date;

  @Prop({ required: false })
  telefono_emergencia?: string;

  @Prop({ type: InstitucionEmbebidaSchema, required: false })
  institucion?: InstitucionEmbebida;

  @Prop({ required: false })
  especialidad?: string;

  @Prop({ required: false })
  telefono_consultorio?: string;

  @Prop({ required: false })
  anios_experiencia?: number;

  @Prop({ required: false })
  registro_mpi?: string;
}

export const UsuarioSchema = SchemaFactory.createForClass(Usuario);

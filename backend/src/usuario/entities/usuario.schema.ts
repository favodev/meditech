import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { TipoUsuario } from '@enums/tipo_usuario.enum';
import { Sexo } from '@enums/sexo.enum';
import { MedicamentoAnticoagulante } from '@enums/medicamento_anticoagulante.enum';

@Schema({ _id: false })
class RangoMeta {
  @Prop({ required: true, type: Number })
  min: number; // Ej: 2.0

  @Prop({ required: true, type: Number })
  max: number; // Ej: 3.0
}
const RangoMetaSchema = SchemaFactory.createForClass(RangoMeta);

@Schema({ _id: false })
class DatosAnticoagulacion {
  @Prop({
    required: true,
    enum: Object.values(MedicamentoAnticoagulante),
    type: String,
  })
  medicamento: string;

  @Prop({ required: true, type: Number, default: 4 })
  mg_por_pastilla: number; // Ej: 4 para Aceno, 5 para Warfarina

  @Prop({ type: RangoMetaSchema, required: true })
  rango_meta: RangoMeta; // [cite: 611-614]

  @Prop({ required: false })
  diagnostico_base?: string; // Ej: "Válvula Mecánica" [cite: 611-612]

  @Prop({ required: false })
  fecha_inicio_tratamiento?: Date;
}
const DatosAnticoagulacionSchema =
  SchemaFactory.createForClass(DatosAnticoagulacion);

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

  @Prop({ required: false })
  twoFactorSecret?: string;

  @Prop({ required: false, default: false })
  isTwoFactorEnabled?: boolean;

  @Prop({ type: DatosAnticoagulacionSchema, required: false })
  datos_anticoagulacion?: DatosAnticoagulacion;

  @Prop({ required: false })
  passwordResetToken?: string; // Guardaremos el HASH del token, no el token real

  @Prop({ required: false })
  passwordResetExpires?: Date; // Fecha límite para usarlo
}

export const UsuarioSchema = SchemaFactory.createForClass(Usuario);

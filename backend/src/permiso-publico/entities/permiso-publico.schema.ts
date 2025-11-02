import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { NivelAcceso } from '@enums/nivel_acceso.enum';
import {
  Archivo,
  ArchivoSchema,
} from '@modules/informe/entities/informe.schema';

@Schema({ _id: false })
class InformeEmbebido {
  @Prop({ required: true })
  titulo: string;

  @Prop({ required: true })
  tipo_informe: string;

  @Prop()
  observaciones?: string;

  @Prop({ type: [ArchivoSchema] })
  archivos: Archivo[];
}
const InformeEmbebidoSchema = SchemaFactory.createForClass(InformeEmbebido);

@Schema({ timestamps: true, collection: 'permiso-publico' })
export class PermisoPublico extends Document {
  @Prop({ required: true, unique: true, index: true })
  token: string;

  @Prop({ required: true, index: true })
  run_paciente: string;

  @Prop({ type: Types.ObjectId, ref: 'Informe', required: true })
  informe_id_original: Types.ObjectId;

  @Prop({ type: String, enum: Object.values(NivelAcceso), required: true })
  nivel_acceso: NivelAcceso;

  @Prop({ required: true, index: true })
  fecha_limite: Date;

  @Prop({ type: InformeEmbebidoSchema, required: true })
  informe: InformeEmbebido;
}

export const PermisoPublicoSchema =
  SchemaFactory.createForClass(PermisoPublico);

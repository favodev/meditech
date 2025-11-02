import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { NivelAcceso } from '@enums/nivel_acceso.enum';
import { Archivo, ArchivoSchema } from '@informe/entities/informe.schema';

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

@Schema({ timestamps: true, collection: 'permiso-compartir' })
export class PermisoCompartir extends Document {
  @Prop({ type: String, enum: Object.values(NivelAcceso), required: true })
  nivel_acceso: NivelAcceso;

  @Prop({ required: true })
  fecha_limite: Date;

  @Prop({ type: Types.ObjectId, ref: 'Informe', required: true })
  informe_id_original: Types.ObjectId;

  @Prop({ required: true, index: true })
  run_paciente: string;

  @Prop({ required: true })
  run_medico: string;

  @Prop({ type: InformeEmbebidoSchema, required: true })
  informe: InformeEmbebido;
}

export const PermisoCompartirSchema =
  SchemaFactory.createForClass(PermisoCompartir);

PermisoCompartirSchema.index({ run_medico: 1, fecha_limite: 1 });

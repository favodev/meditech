import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { NivelAcceso } from '@enums/nivel_acceso.enum';
import { Archivo, ArchivoSchema } from '@informe/entities/informe.schema';

@Schema({ _id: false })
class CalendarioDosis {
  @Prop({ type: String }) lunes: string;
  @Prop({ type: String }) martes: string;
  @Prop({ type: String }) miercoles: string;
  @Prop({ type: String }) jueves: string;
  @Prop({ type: String }) viernes: string;
  @Prop({ type: String }) sabado: string;
  @Prop({ type: String }) domingo: string;
}
const CalendarioDosisSchema = SchemaFactory.createForClass(CalendarioDosis);

@Schema({ _id: false })
class ContenidoClinico {
  @Prop({ type: Number })
  inr_actual?: number;

  @Prop({ type: Date })
  fecha_proximo_control?: Date;

  @Prop({ type: CalendarioDosisSchema })
  dosis_diaria?: CalendarioDosis;

  @Prop({ type: Number })
  dosis_semanal_total_mg?: number;

  @Prop({ type: String })
  observaciones_clinicas?: string;
}
const ContenidoClinicoSchema = SchemaFactory.createForClass(ContenidoClinico);

@Schema({ _id: false })
class InformeEmbebido {
  @Prop({ required: true })
  titulo: string;

  @Prop({ required: true })
  tipo_informe: string;

  @Prop()
  observaciones?: string;

  @Prop({ type: ContenidoClinicoSchema, required: false })
  contenido_clinico?: ContenidoClinico;

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

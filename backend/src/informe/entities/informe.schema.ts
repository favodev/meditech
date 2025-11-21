import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

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
export class Archivo {
  @Prop({ required: true })
  nombre: string;

  @Prop({ required: true })
  formato: string;

  @Prop({ required: true })
  urlpath: string;

  @Prop({ required: true })
  tipo: string;
}
export const ArchivoSchema = SchemaFactory.createForClass(Archivo);

@Schema({ timestamps: true, collection: 'informes' })
export class Informe extends Document {
  @Prop({ required: true })
  titulo: string;

  @Prop({ required: true })
  tipo_informe: string;

  @Prop()
  observaciones?: string;

  @Prop({ required: true, index: true })
  run_paciente: string;

  @Prop({ required: true, index: true })
  run_medico: string;

  @Prop({ type: ContenidoClinicoSchema, required: false })
  contenido_clinico?: ContenidoClinico;

  @Prop({ type: [ArchivoSchema] })
  archivos: Archivo[];
}

export const InformeSchema = SchemaFactory.createForClass(Informe);

InformeSchema.index({ run_medico: 1, createdAt: 1 });

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ _id: false })
export class Archivo {
  @Prop({ required: true })
  nombre: string;

  @Prop({ required: true })
  formato: string;

  @Prop({ required: true })
  urlpath: string;
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

  @Prop({ type: [ArchivoSchema] })
  archivos: Archivo[];
}

export const InformeSchema = SchemaFactory.createForClass(Informe);

InformeSchema.index({ run_medico: 1, fecha_limite: 1 });

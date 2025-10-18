import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { TipoInforme } from '../../common/enums/tipo_informe.enum';

// --- SUB-DOCUMENTO PARA LOS ARCHIVOS ANIDADOS ---
@Schema({ _id: false }) // _id: false para que no genere IDs para cada archivo
class Archivo {
  @Prop({ required: true })
  nombre: string; // El nombre original del archivo para mostrar al usuario

  @Prop({ required: true })
  formato: string; // El tipo MIME del archivo, ej: 'application/pdf'

  @Prop({ required: true })
  urlpath: string; // La ruta/path del archivo en Cloud Storage
}

const ArchivoSchema = SchemaFactory.createForClass(Archivo);

// --- ESQUEMA PRINCIPAL DEL INFORME ---
@Schema({ timestamps: true }) // timestamps: true añade createdAt y updatedAt
export class Informe extends Document {
  @Prop({ required: true })
  titulo: string;

  @Prop({ type: String, enum: Object.values(TipoInforme), required: true })
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

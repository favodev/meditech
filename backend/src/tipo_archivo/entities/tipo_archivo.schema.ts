import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ collection: 'tipo_archivos' })
export class TipoArchivo extends Document {
  @Prop({ required: true, unique: true })
  nombre: string;
}

export const TipoArchivoSchema = SchemaFactory.createForClass(TipoArchivo);

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ collection: 'tipo_informes' })
export class TipoInforme extends Document {
  @Prop({ required: true, unique: true })
  nombre: string;
}

export const TipoInformeSchema = SchemaFactory.createForClass(TipoInforme);

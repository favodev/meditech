import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ collection: 'instituciones' })
export class Institucion extends Document {
  @Prop({ required: true, unique: true })
  nombre: string;

  @Prop({ required: true })
  tipo_institucion: string;
}

export const InstitucionSchema = SchemaFactory.createForClass(Institucion);

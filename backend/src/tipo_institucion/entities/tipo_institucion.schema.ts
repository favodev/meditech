import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ collection: 'tipo_instituciones' })
export class TipoInstitucion extends Document {
  @Prop({ required: true, unique: true })
  nombre: string;
}

export const TipoInstitucionSchema =
  SchemaFactory.createForClass(TipoInstitucion);

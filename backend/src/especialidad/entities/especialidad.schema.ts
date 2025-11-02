import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ collection: 'especialidades' })
export class Especialidad extends Document {
  @Prop({ required: true, unique: true })
  nombre: string;
}

export const EspecialidadSchema = SchemaFactory.createForClass(Especialidad);

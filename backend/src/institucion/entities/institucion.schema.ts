import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { TipoInstitucion } from '@enums/tipo_institucion.enum';

@Schema({ collection: 'instituciones' })
export class Institucion extends Document {
  @Prop({ required: true, unique: true })
  nombre: string;

  @Prop({
    type: String,
    enum: Object.values(TipoInstitucion),
    required: true,
  })
  tipo_institucion: string;
}

export const InstitucionSchema = SchemaFactory.createForClass(Institucion);

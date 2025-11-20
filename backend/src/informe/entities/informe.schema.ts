import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

// ==========================================
// 1. Sub-Schema: Calendario de Dosis (Visual)
// ==========================================
// Representa la instrucción visual (ej: "1/2") para cada día.
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

// ==========================================
// 2. Sub-Schema: Contenido Clínico (TACO)
// ==========================================
// El "cerebro" del Carnet. Solo se llena si es un Control de Anticoagulación.
@Schema({ _id: false })
class ContenidoClinico {
  // El dato crítico: Resultado del laboratorio
  @Prop({ type: Number })
  inr_actual?: number;

  // La instrucción administrativa: Cuándo volver
  @Prop({ type: Date })
  fecha_proximo_control?: Date;

  // La instrucción visual: Qué tomar cada día
  @Prop({ type: CalendarioDosisSchema })
  dosis_diaria?: CalendarioDosis;

  // El dato oculto: Suma total en mg (Calculado por backend)
  @Prop({ type: Number })
  dosis_semanal_total_mg?: number;

  // Notas extra (ej: "Dieta", "Suspensión por cirugía")
  @Prop({ type: String })
  observaciones_clinicas?: string;
}
const ContenidoClinicoSchema = SchemaFactory.createForClass(ContenidoClinico);

// ==========================================
// 3. Sub-Schema: Archivo (Existente)
// ==========================================
// La evidencia legal (PDF o Foto del examen/papel)
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

// ==========================================
// 4. Schema Principal: Informe (La Fila del Carnet)
// ==========================================
@Schema({ timestamps: true, collection: 'informes' })
export class Informe extends Document {
  @Prop({ required: true })
  titulo: string;

  @Prop({ required: true })
  tipo_informe: string; // Ej: 'Control de Anticoagulación'

  @Prop()
  observaciones?: string; // Observaciones generales del informe (no clínicas)

  @Prop({ required: true, index: true })
  run_paciente: string;

  @Prop({ required: true, index: true })
  run_medico: string;

  // --- EL NUEVO BOLSILLO INTELIGENTE ---
  // Opcional: Solo existe si el informe es de tipo TACO
  @Prop({ type: ContenidoClinicoSchema, required: false })
  contenido_clinico?: ContenidoClinico;

  @Prop({ type: [ArchivoSchema] })
  archivos: Archivo[];
}

export const InformeSchema = SchemaFactory.createForClass(Informe);

// Índices para búsqueda rápida (ej: "Muéstrame los últimos controles de este médico")
InformeSchema.index({ run_medico: 1, createdAt: 1 });

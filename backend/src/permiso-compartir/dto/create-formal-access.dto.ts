import { IsNotEmpty, IsNumber, IsMongoId } from 'class-validator';
import { IsRUT } from '@decorator/rut.decorators';

export class CreateFormalAccessDto {
  @IsRUT()
  @IsNotEmpty()
  doctorRun: string;

  @IsMongoId()
  @IsNotEmpty()
  reportId: string;

  @IsNumber()
  @IsNotEmpty()
  expiryDays: number;
}

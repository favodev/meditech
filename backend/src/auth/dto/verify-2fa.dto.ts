import { IsNumberString, IsNotEmpty, Length } from 'class-validator';

export class Verify2faDto {
  @IsNumberString()
  @Length(6, 6)
  @IsNotEmpty()
  code: string;
}

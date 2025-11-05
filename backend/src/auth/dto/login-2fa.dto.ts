import {
  IsJWT,
  IsNotEmpty,
  IsString,
  IsNumberString,
  Length,
} from 'class-validator';

export class Login2faDto {
  @IsJWT()
  @IsNotEmpty()
  tempToken: string;

  @IsNumberString()
  @Length(6, 6)
  @IsNotEmpty()
  code: string;
}

import { IsString, IsNotEmpty } from 'class-validator';

export class getDownloadUrlDto {
  @IsString()
  @IsNotEmpty()
  path: string;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  format: string;
}

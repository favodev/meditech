import { IsString, IsNotEmpty } from 'class-validator';

export class getOpenUrlDto {
  @IsString()
  @IsNotEmpty()
  path: string;
}

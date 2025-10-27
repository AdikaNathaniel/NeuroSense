import { IsString, IsNotEmpty, IsEmail } from 'class-validator';

export class ForgotPasswordDto {
  @IsString()
  @IsNotEmpty()
  username: string;
}
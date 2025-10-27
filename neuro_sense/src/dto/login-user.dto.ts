import { IsString, IsNotEmpty, IsIn } from 'class-validator';

export class LoginUserDto {
  @IsString()
  @IsNotEmpty()
  username: string;

  @IsString()
  @IsNotEmpty()
  password: string;

  @IsString()
  @IsIn(['user', 'admin', 'moderator'])
  role: string;
}
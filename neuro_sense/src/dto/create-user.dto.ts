import { IsString, IsNotEmpty, MinLength, IsIn } from 'class-validator';

export class CreateUserDto {
  @IsString()
  @IsNotEmpty()
  username: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  password: string;

  @IsString()
  @IsNotEmpty()
  GhanaCard: string;

  @IsString()
  @IsIn(['user', 'admin', 'moderator'])
  role: string;
}
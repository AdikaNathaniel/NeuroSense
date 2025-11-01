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
  email: string;

  @IsString()
  @IsNotEmpty()
  GhanaCard: string;

  @IsString()
  @IsIn(['celebral-mother', 'admin', 'celebral-patient', 'celebral-caregiver'])
  role: string;
}
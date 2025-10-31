import { IsString, IsOptional, IsNotEmpty, MinLength, ValidateIf } from 'class-validator';

export class UpdateUserDto {
  @IsString()
  @IsNotEmpty()
  username: string;

  @IsString()
  @IsOptional()
  @MinLength(2)
  name?: string;

  @IsString()
  @IsOptional()
  @MinLength(6)
  @ValidateIf(o => o.newPassword) 
  oldPassword?: string;

  @IsString()
  @IsOptional()
  @MinLength(6)
  newPassword?: string;
}
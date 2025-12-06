import { IsString, IsEmail, IsPhoneNumber, IsObject, IsOptional, IsBoolean, IsNumber, IsUrl, MinLength } from 'class-validator';

export class CreateFacilityDto {
  @IsString()
  @MinLength(3)
  facilityName: string;

  @IsString()
  image: string;

  @IsEmail()
  email: string;

  @IsString()
  @IsPhoneNumber()
  phoneNumber: string;

  @IsObject()
  location: {
    address: string;
    city: string;
    state: string;
    country: string;
  };


  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsUrl()
  website?: string;

  @IsOptional()
  @IsNumber()
  establishedYear?: number;
}
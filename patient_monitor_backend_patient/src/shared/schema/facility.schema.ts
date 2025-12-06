// src/facilities/schemas/facility.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Facility extends Document {
  @Prop({ required: true, unique: true, trim: true })
  facilityName: string;

  @Prop({ required: true, trim: true })
  image: string; // URL or base64 string

  @Prop({ required: true, trim: true, lowercase: true })
  email: string;

  @Prop({ required: true, trim: true })
  phoneNumber: string;

  @Prop({
    type: {
      address: String,
      city: String,
      state: String,
      country: String
    },
    required: true,
  })
  location: {
    address: string;
    city: string;
    state: string;
    country: string;
  };

  @Prop({ default: true })
  isActive: boolean;


  @Prop()
  description: string;

  @Prop()
  website: string;

  @Prop()
  establishedYear: number;
}

export const FacilitySchema = SchemaFactory.createForClass(Facility);
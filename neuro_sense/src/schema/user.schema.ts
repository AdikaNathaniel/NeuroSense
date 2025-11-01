// import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
// import { Document } from 'mongoose';

// export type UserDocument = User & Document;

// @Schema({ timestamps: true })
// export class User {
//   @Prop({ required: true, unique: true })
//   username: string;

//   @Prop({ required: true })
//   password: string;

//   @Prop({ required: true, unique: true })
//   GhanaCard: string;

//   @Prop({ required: true, enum: ['celebral-mother', 'admin', 'celebral-patient', 'celebral-caregiver'], default: 'celebral-mother' })
//   role: string;

//   @Prop()
//   refreshToken: string;

//   @Prop()
//   resetPasswordToken: string;

//   @Prop()
//   resetPasswordExpires: Date;
// }

// export const UserSchema = SchemaFactory.createForClass(User);


import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type UserDocument = User & Document;

@Schema({ timestamps: true })
export class User {
  @Prop({ required: true, unique: true })
  username: string;

  @Prop({ required: true })
  password: string;

  @Prop({ required: true, unique: true })
  GhanaCard: string;

  @Prop({ required: true, enum: ['celebral-mother', 'admin', 'celebral-patient', 'celebral-caregiver'] })
  role: string;

  @Prop()
  refreshToken?: string;

  @Prop()
  resetPasswordToken?: string;

  @Prop()
  resetPasswordExpires?: Date;

  // ADD THESE FIELDS:
  @Prop({ default: true })
  isActive: boolean;

  @Prop({ default: true })
  isVerified: boolean;

  @Prop({ default: 0 })
  failedLoginAttempts: number;

  @Prop()
  lockUntil?: Date;
}

export const UserSchema = SchemaFactory.createForClass(User);
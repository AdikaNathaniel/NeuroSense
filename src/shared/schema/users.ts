import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum userTypes {
  ADMIN = 'admin',
  CELEBRAL_MOTHER = 'celebral-mother',
  CELEBRAL_PHYSICIAN = 'celebral-physician',
  RELATIVE = 'relative',
  GENERALUSER = 'wellness-user',
  CELEBRAL_CAREGIVER = 'celebral-caregiver',
}

@Schema({
  timestamps: true,
})
export class Users extends Document {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  email: string;

  @Prop({ required: true })
  card: string;

  @Prop({ required: true })
  password: string;

  @Prop({
    required: true,
    enum: [
      userTypes.ADMIN,
      userTypes.CELEBRAL_MOTHER,
      userTypes.CELEBRAL_PHYSICIAN,
      userTypes.RELATIVE,
      userTypes.GENERALUSER,
      userTypes.CELEBRAL_CAREGIVER,
    ],
  })
  type: string;

  @Prop({ default: false })
  isVerified: boolean;

  @Prop({ default: null })
  otp: string | null;

  @Prop({ default: null })
  otpExpiryTime: Date | null;
}

export const UserSchema = SchemaFactory.createForClass(Users);

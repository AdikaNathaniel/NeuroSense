import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum userTypes {
  ADMIN = 'admin',
  CELEBRAL_MOTHER = 'celebral-mother',
  CELEBRAL_CAREGIVER = 'celebral-caregiver',
  CELEBRAL_PHYSICIAN = 'celebral-physician',
  RELATIVE = 'relative',
  GENERALUSER = 'wellness-user',
}


//  @Prop({ required: true, enum: ['celebral-mother', 'admin', 'celebral-patient', 'celebral-caregiver'], default: 'celebral-mother' })

@Schema({
  timestamps: true,
})
export class Users extends Document {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true, unique: true })
  username: string;


  @Prop({ required: true, unique: true })
  email: string;

  @Prop({ required: true })
  card: string;

  @Prop({ required: false, unique: true })
  GhanaCard: string;

  @Prop({ required: true })
  password: string;

  @Prop({
    required: true,
    enum: [
      userTypes.ADMIN,
      userTypes. CELEBRAL_MOTHER,
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

  @Prop({ default: true })
  isActive: boolean;

  @Prop({ default: 0 })
  failedLoginAttempts: number;

  @Prop({ default: null })
  lockUntil: Date | null;
}

export const UserSchema = SchemaFactory.createForClass(Users);
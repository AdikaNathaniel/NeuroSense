import { Injectable, UnauthorizedException, BadRequestException, ConflictException, HttpException, HttpStatus } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { JwtService } from '@nestjs/jwt';
import { User, UserDocument } from '../schema/user.schema';
import { CreateUserDto } from '../dto/create-user.dto';
import { LoginUserDto } from '../dto/login-user.dto';
import { ChangePasswordDto } from '../dto/change-password.dto';
import { UpdateUserDto } from '../dto/update-user.dto';
import { EmailService } from '../email/email.service';

@Injectable()
export class AuthService {
  private readonly MAX_FAILED_ATTEMPTS = 3;
  private readonly ACCOUNT_LOCK_DURATION = 30 * 60 * 1000; // 30 minutes

  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    private jwtService: JwtService,
    private emailService: EmailService, // Add EmailService
  ) {}

  async register(createUserDto: CreateUserDto): Promise<{ 
    success: boolean;
    message: string; 
    result?: any 
  }> {
    const { username, password, GhanaCard, role } = createUserDto;

    try {
      // Check if user already exists
      const existingUser = await this.userModel.findOne({
        $or: [{ username }, { GhanaCard }],
      });

      if (existingUser) {
        throw new ConflictException('User with this username or Ghana Card already exists');
      }

      // Hash password
      const hashedPassword = await bcrypt.hash(password, 10);

      // Generate OTP for email verification
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      const otpExpiryTime = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

      // Create user
      const user = await this.userModel.create({
        username,
        password: hashedPassword,
        GhanaCard,
        role,
        isVerified: false, // Email verification required
        isActive: true,
        failedLoginAttempts: 0,
        otp,
        otpExpiryTime,
      });

      // Send OTP email
      const emailResult = await this.emailService.sendOTPEmail(username, otp);

      if (!emailResult.success) {
        // If email fails, delete the user and throw error
        await this.userModel.findByIdAndDelete(user._id);
        throw new Error(`Failed to send verification email: ${emailResult.message}`);
      }

      // Remove sensitive data from response
      const userObject: any = user.toObject();
      delete userObject.password;
      delete userObject.refreshToken;
      delete userObject.otp;

      return {
        success: true,
        message: 'User registered successfully. Please check your email for verification OTP.',
        result: {
          user: userObject,
          emailSent: true
        }
      };
    } catch (error) {
      throw error;
    }
  }

  async login(loginUserDto: LoginUserDto): Promise<{ 
    success: boolean; 
    message: string; 
    result?: { 
      user: any; 
      token: string;
      accessToken?: string;
      refreshToken?: string;
    } 
  }> {
    const { username, password, role } = loginUserDto;

    try {
      const user = await this.userModel.findOne({ username, role });
      if (!user) {
        throw new Error('Invalid username or password');
      }

      // Check if account is locked
      if ((user as any).lockUntil && (user as any).lockUntil > new Date()) {
        const remainingTime = Math.ceil(((user as any).lockUntil.getTime() - Date.now()) / (60 * 1000));
        throw new Error(`Account is temporarily locked. Try again after ${remainingTime} minutes.`);
      }

      if (!(user as any).isActive) {
        throw new Error('Your account is deactivated. Please contact support.');
      }

      // Check if email is verified
      if (!(user as any).isVerified) {
        throw new Error('Please verify your email before logging in.');
      }

      // Check password
      const isPasswordValid = await bcrypt.compare(password, user.password);
      
      if (!isPasswordValid) {
        const updatedFailedAttempts = (user as any).failedLoginAttempts + 1;
        let lockUntil = null;
        
        if (updatedFailedAttempts >= this.MAX_FAILED_ATTEMPTS) {
          lockUntil = new Date(Date.now() + this.ACCOUNT_LOCK_DURATION);
          await this.userModel.findByIdAndUpdate(user._id, {
            failedLoginAttempts: updatedFailedAttempts,
            lockUntil,
            isActive: false
          });
          
          throw new Error('Your account has been deactivated due to multiple failed attempts. Please contact support.');
        } else {
          await this.userModel.findByIdAndUpdate(user._id, {
            failedLoginAttempts: updatedFailedAttempts,
            lockUntil: updatedFailedAttempts === this.MAX_FAILED_ATTEMPTS - 1 ? 
              new Date(Date.now() + this.ACCOUNT_LOCK_DURATION) : null
          });
          throw new Error(`Invalid username or password. ${this.MAX_FAILED_ATTEMPTS - updatedFailedAttempts} attempts remaining.`);
        }
      }

      // Reset failed attempts on successful login
      if ((user as any).failedLoginAttempts > 0 || (user as any).lockUntil) {
        await this.userModel.findByIdAndUpdate(user._id, {
          failedLoginAttempts: 0,
          lockUntil: null
        });
      }

      // Generate tokens
      const payload = { username: user.username, sub: user._id.toString(), role: user.role };
      const accessToken = this.jwtService.sign(payload);
      const refreshToken = this.jwtService.sign(payload, { expiresIn: '7d' });

      // Save refresh token
      await this.userModel.findByIdAndUpdate(user._id, { refreshToken });

      // Remove sensitive data
      const userObject: any = user.toObject();
      delete userObject.password;
      delete userObject.refreshToken;

      return {
        success: true,
        message: 'Login successful',
        result: {
          user: {
            id: user._id.toString(),
            username: user.username,
            GhanaCard: user.GhanaCard,
            role: user.role,
            isActive: (user as any).isActive,
            isVerified: (user as any).isVerified
          },
          token: accessToken,
          accessToken,
          refreshToken
        },
      };
    } catch (error) {
      throw error;
    }
  }

  async verifyEmail(otp: string, username: string): Promise<{ 
    success: boolean; 
    message: string; 
  }> {
    try {
      const user = await this.userModel.findOne({ username });
      if (!user) {
        throw new Error('User not found');
      }

      if ((user as any).otp !== otp) {
        throw new Error('Invalid OTP');
      }

      // Check if OTP is expired
      if ((user as any).otpExpiryTime && (user as any).otpExpiryTime < new Date()) {
        throw new Error('OTP has expired. Please request a new one.');
      }

      await this.userModel.findByIdAndUpdate(user._id, { 
        isVerified: true, 
        otp: null, 
        otpExpiryTime: null,
        isActive: true,
        failedLoginAttempts: 0,
        lockUntil: null
      });

      return {
        success: true,
        message: 'Email verified successfully. You can log in now.',
      };
    } catch (error) {
      throw error;
    }
  }

  async sendOtpEmail(username: string): Promise<{ 
    success: boolean; 
    message: string; 
    result?: { email: string } 
  }> {
    try {
      const user = await this.userModel.findOne({ username });
      if (!user) {
        throw new Error('User not found');
      }

      if ((user as any).isVerified) {
        throw new Error('Email already verified');
      }

      // Generate new OTP
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      const otpExpiryTime = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

      await this.userModel.findByIdAndUpdate(user._id, {
        otp,
        otpExpiryTime
      });

      // Send OTP email
      const emailResult = await this.emailService.sendOTPEmail(username, otp);

      if (!emailResult.success) {
        throw new Error(`Failed to send OTP: ${emailResult.message}`);
      }

      return {
        success: true,
        message: 'OTP sent successfully',
        result: { email: username }
      };
    } catch (error) {
      throw error;
    }
  }

  async forgotPassword(username: string): Promise<{ 
    success: boolean; 
    message: string; 
    result?: { email: string } 
  }> {
    try {
      const user = await this.userModel.findOne({ username });
      if (!user) {
        // Don't reveal if user exists for security
        return {
          success: true,
          message: 'If the username exists, a reset password has been sent to your email',
        };
      }

      if (!(user as any).isActive) {
        throw new Error('Your account is deactivated. Please contact support.');
      }

      // Generate temporary password
      const tempPassword = Math.random().toString(36).substring(2, 12);
      const hashedPassword = await bcrypt.hash(tempPassword, 10);

      await this.userModel.findByIdAndUpdate(user._id, { 
        password: hashedPassword,
        failedLoginAttempts: 0,
        lockUntil: null
      });

      // Send forgot password email
      const emailResponse = await this.emailService.sendForgotPasswordEmail(username, tempPassword);

      if (!emailResponse.success) {
        throw new Error(emailResponse.message);
      }

      return {
        success: true,
        message: 'New password sent to your email',
        result: { email: username },
      };
    } catch (error) {
      throw error;
    }
  }

  async resetPassword(token: string, newPassword: string): Promise<{ 
    success: boolean; 
    message: string; 
  }> {
    try {
      const user = await this.userModel.findOne({
        resetPasswordToken: token,
        resetPasswordExpires: { $gt: new Date() },
      });

      if (!user) {
        throw new Error('Invalid or expired reset token');
      }

      // Hash new password
      const hashedPassword = await bcrypt.hash(newPassword, 10);

      // Update password and clear reset token
      await this.userModel.findByIdAndUpdate(user._id, {
        password: hashedPassword,
        resetPasswordToken: undefined,
        resetPasswordExpires: undefined,
        failedLoginAttempts: 0,
        lockUntil: null
      });

      return { 
        success: true, 
        message: 'Password reset successfully' 
      };
    } catch (error) {
      throw error;
    }
  }

  async getUserProfile(userId: string): Promise<{ 
    success: boolean; 
    message: string; 
    result: any 
  }> {
    try {
      const user = await this.userModel.findById(userId).select('-password -refreshToken -otp');
      
      if (!user) {
        throw new Error('User not found');
      }

      return {
        success: true,
        message: 'User profile fetched successfully',
        result: {
          id: user._id.toString(),
          username: user.username,
          GhanaCard: user.GhanaCard,
          role: user.role,
          isActive: (user as any).isActive,
          isVerified: (user as any).isVerified
        }
      };
    } catch (error) {
      throw error;
    }
  }

  async changePassword(userId: string, changePasswordDto: ChangePasswordDto): Promise<{ 
    success: boolean; 
    message: string; 
  }> {
    try {
      const { currentPassword, newPassword } = changePasswordDto;

      const user = await this.userModel.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Verify current password
      const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.password);
      if (!isCurrentPasswordValid) {
        throw new Error('Current password is incorrect');
      }

      // Hash new password
      const hashedPassword = await bcrypt.hash(newPassword, 10);
      await this.userModel.findByIdAndUpdate(userId, { 
        password: hashedPassword,
        failedLoginAttempts: 0,
        lockUntil: null
      });

      return { 
        success: true, 
        message: 'Password changed successfully' 
      };
    } catch (error) {
      throw error;
    }
  }

  async findAll(type?: string): Promise<{ 
    success: boolean; 
    message: string; 
    result: any[] 
  }> {
    try {
      const query = type ? { role: type } : {};
      const users = await this.userModel.find(query).select('-password -refreshToken -otp').lean();
  
      const userList = (users as any[]).map((user) => ({
        id: user._id.toString(),
        username: user.username,
        GhanaCard: user.GhanaCard,
        role: user.role,
        isVerified: user.isVerified,
        isActive: user.isActive,
        failedLoginAttempts: user.failedLoginAttempts
      }));
  
      return {
        success: true,
        message: 'Users fetched successfully',
        result: userList,
      };
    } catch (error) {
      throw error;
    }
  }

  async updatePasswordOrName(updateUserDto: UpdateUserDto): Promise<{ 
    success: boolean; 
    message: string; 
    result: any 
  }> {
    try {
      const { username, oldPassword, newPassword, name } = updateUserDto;
      
      if (!name && !newPassword) {
        throw new Error('Please provide name or password');
      }

      const user = await this.userModel.findOne({ username });
      if (!user) {
        throw new Error('User not found');
      }

      if (!(user as any).isActive) {
        throw new Error('Your account is deactivated. Please contact support.');
      }

      const updateData: any = {};

      if (newPassword) {
        const isPasswordMatch = await bcrypt.compare(oldPassword, user.password);
        if (!isPasswordMatch) {
          throw new Error('Invalid current password');
        }
        updateData.password = await bcrypt.hash(newPassword, 10);
        updateData.failedLoginAttempts = 0;
        updateData.lockUntil = null;
      }

      if (name) {
        updateData.username = name;
      }

      await this.userModel.findByIdAndUpdate(user._id, updateData);

      return {
        success: true,
        message: 'User updated successfully',
        result: {
          username: updateData.username || user.username,
          GhanaCard: user.GhanaCard,
          role: user.role,
          id: user._id.toString(),
        },
      };
    } catch (error) {
      throw error;
    }
  }

  async reactivateAccount(username: string, adminUsername: string): Promise<{ 
    success: boolean; 
    message: string; 
    result: any 
  }> {
    try {
      // Verify admin status
      const adminUser = await this.userModel.findOne({ username: adminUsername, role: 'admin' });
      if (!adminUser) {
        throw new Error('Only admin can reactivate accounts');
      }

      const user = await this.userModel.findOne({ username }) as any;
      if (!user) {
        throw new Error('User not found');
      }

      // Check if account needs reactivation
      const isLocked = user.lockUntil && user.lockUntil > new Date();
      const isInactive = !user.isActive;
      const hasFailedAttempts = user.failedLoginAttempts > 0;

      if (!isLocked && !isInactive && !hasFailedAttempts) {
        throw new Error('Account is already active and unlocked');
      }

      // Reactivate the account
      await this.userModel.findByIdAndUpdate(user._id, {
        isActive: true,
        failedLoginAttempts: 0,
        lockUntil: null
      });

      return {
        success: true,
        message: 'Account reactivated and unlocked successfully',
        result: {
          username: user.username,
          GhanaCard: user.GhanaCard,
          reactivatedBy: adminUsername
        }
      };
    } catch (error) {
      throw error;
    }
  }

  async refreshToken(refreshToken: string): Promise<{ 
    success: boolean; 
    message: string; 
    result?: { accessToken: string } 
  }> {
    try {
      const payload = this.jwtService.verify(refreshToken);
      const user = await this.userModel.findById(payload.sub);

      if (!user || user.refreshToken !== refreshToken) {
        throw new Error('Invalid refresh token');
      }

      const newPayload = { username: user.username, sub: user._id.toString(), role: user.role };
      const accessToken = this.jwtService.sign(newPayload);

      return { 
        success: true, 
        message: 'Token refreshed successfully',
        result: { accessToken } 
      };
    } catch (error) {
      throw new Error('Invalid refresh token');
    }
  }

  async logout(userId: string): Promise<{ 
    success: boolean; 
    message: string; 
  }> {
    try {
      await this.userModel.findByIdAndUpdate(userId, { refreshToken: null });
      return { 
        success: true, 
        message: 'Logged out successfully' 
      };
    } catch (error) {
      throw error;
    }
  }

  async validateUser(username: string, password: string): Promise<any> {
    const user = await this.userModel.findOne({ username });
    if (user && await bcrypt.compare(password, user.password)) {
      const { password, ...result } = user.toObject();
      return result;
    }
    return null;
  }
}
import { Injectable, UnauthorizedException, BadRequestException, ConflictException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { JwtService } from '@nestjs/jwt';
import { User, UserDocument } from '../schema/user.schema';
import { CreateUserDto } from '../dto/create-user.dto';
import { LoginUserDto } from '../dto/login-user.dto';
import { ChangePasswordDto } from '../dto/change-password.dto';

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    private jwtService: JwtService,
  ) {}

  async register(createUserDto: CreateUserDto): Promise<{ message: string; user: any }> {
    const { username, password, GhanaCard, role } = createUserDto;

    // Check if user already exists
    const existingUser = await this.userModel.findOne({
      $or: [{ username }, { GhanaCard }],
    });

    if (existingUser) {
      throw new ConflictException('User with this username or Ghana Card already exists');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const user = await this.userModel.create({
      username,
      password: hashedPassword,
      GhanaCard,
      role,
    });

    // Remove password from response
    const userObject = user.toObject();
    delete userObject.password;
    delete userObject.refreshToken;

    return {
      message: 'User registered successfully',
      user: userObject,
    };
  }

  async login(loginUserDto: LoginUserDto): Promise<{ accessToken: string; refreshToken: string; user: any }> {
    const { username, password, role } = loginUserDto;

    // Find user
    const user = await this.userModel.findOne({ username, role });
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Generate tokens
    const payload = { username: user.username, sub: user._id, role: user.role };
    const accessToken = this.jwtService.sign(payload);
    const refreshToken = this.jwtService.sign(payload, { expiresIn: '7d' });

    // Save refresh token
    user.refreshToken = refreshToken;
    await user.save();

    // Remove sensitive data
    const userObject = user.toObject();
    delete userObject.password;
    delete userObject.refreshToken;

    return {
      accessToken,
      refreshToken,
      user: userObject,
    };
  }

  async forgotPassword(username: string): Promise<{ message: string; resetToken: string }> {
    const user = await this.userModel.findOne({ username });
    if (!user) {
      // Don't reveal if user exists or not for security
      return {
        message: 'If the username exists, a reset token has been sent',
        resetToken: 'dummy-token-for-security', // In production, you might not return this
      };
    }

    // Generate reset token
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenExpiry = new Date(Date.now() + 3600000); // 1 hour

    user.resetPasswordToken = resetToken;
    user.resetPasswordExpires = resetTokenExpiry;
    await user.save();

    // In a real application, you would send an email with the reset token
    console.log(`Reset token for ${username}: ${resetToken}`);

    return {
      message: 'If the username exists, a reset token has been sent',
      resetToken, // Only for development
    };
  }

  async resetPassword(token: string, newPassword: string): Promise<{ message: string }> {
    const user = await this.userModel.findOne({
      resetPasswordToken: token,
      resetPasswordExpires: { $gt: new Date() },
    });

    if (!user) {
      throw new BadRequestException('Invalid or expired reset token');
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password and clear reset token
    user.password = hashedPassword;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;
    await user.save();

    return { message: 'Password reset successfully' };
  }

  async changePassword(userId: string, changePasswordDto: ChangePasswordDto): Promise<{ message: string }> {
    const { currentPassword, newPassword } = changePasswordDto;

    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    // Verify current password
    const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.password);
    if (!isCurrentPasswordValid) {
      throw new UnauthorizedException('Current password is incorrect');
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await user.save();

    return { message: 'Password changed successfully' };
  }

  async refreshToken(refreshToken: string): Promise<{ accessToken: string }> {
    try {
      const payload = this.jwtService.verify(refreshToken);
      const user = await this.userModel.findById(payload.sub);

      if (!user || user.refreshToken !== refreshToken) {
        throw new UnauthorizedException('Invalid refresh token');
      }

      const newPayload = { username: user.username, sub: user._id, role: user.role };
      const accessToken = this.jwtService.sign(newPayload);

      return { accessToken };
    } catch (error) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  async logout(userId: string): Promise<{ message: string }> {
    await this.userModel.findByIdAndUpdate(userId, { refreshToken: null });
    return { message: 'Logged out successfully' };
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
import { 
  Controller, 
  Post, 
  Body, 
  UseGuards, 
  Req, 
  HttpCode, 
  HttpStatus, 
  Get, 
  Put, 
  Patch, 
  Query,
  Param,
  HttpException 
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { CreateUserDto } from '../dto/create-user.dto';
import { LoginUserDto } from '../dto/login-user.dto';
import { ForgotPasswordDto } from '../dto/forgot-password.dto';
import { ResetPasswordDto } from '../dto/reset-password.dto';
import { ChangePasswordDto } from '../dto/change-password.dto';
import { UpdateUserDto } from '../dto/update-user.dto';
import { JwtAuthGuard } from './jwt-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  async register(@Body() createUserDto: CreateUserDto) {
    try {
      return await this.authService.register(createUserDto);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() loginUserDto: LoginUserDto) {
    try {
      return await this.authService.login(loginUserDto);
    } catch (error) {
      // Handle specific error cases like in UsersController
      if (error.message.includes('deactivated')) {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.FORBIDDEN,
        );
      } else if (error.message.includes('locked')) {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.TOO_MANY_REQUESTS,
        );
      } else if (error.message.includes('Invalid username or password') || error.message.includes('attempts remaining')) {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.UNAUTHORIZED,
        );
      } else {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.BAD_REQUEST,
        );
      }
    }
  }

  @Get('profile')
  @UseGuards(JwtAuthGuard) 
  async getProfile(@Req() req) {
    try {
      return await this.authService.getUserProfile(req.user.sub);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  async forgotPassword(@Body() forgotPasswordDto: ForgotPasswordDto) {
    try {
      return await this.authService.forgotPassword(forgotPasswordDto.username);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  async resetPassword(@Body() resetPasswordDto: ResetPasswordDto) {
    try {
      return await this.authService.resetPassword(resetPasswordDto.token, resetPasswordDto.newPassword);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Patch('update-password-or-name')
  async updatePasswordOrName(@Body() updateUserDto: UpdateUserDto) {
    try {
      return await this.authService.updatePasswordOrName(updateUserDto);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Get()
  async findAll(@Query('type') type: string) {
    try {
      return await this.authService.findAll(type);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Put('reactivate-account/:username')
  async reactivateAccount(
    @Param('username') username: string,
    @Body() body: { adminUsername: string }
  ) {
    try {
      return await this.authService.reactivateAccount(username, body.adminUsername);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Post('change-password')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async changePassword(@Body() changePasswordDto: ChangePasswordDto, @Req() req) {
    try {
      return await this.authService.changePassword(req.user.sub, changePasswordDto);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Post('refresh-token')
  @HttpCode(HttpStatus.OK)
  async refreshToken(@Body('refreshToken') refreshToken: string) {
    try {
      return await this.authService.refreshToken(refreshToken);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async logout(@Req() req) {
    try {
      return await this.authService.logout(req.user.sub);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }
}

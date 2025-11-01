import { Injectable } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private transporter;

  constructor() {
    this.initializeTransporter();
  }

  private initializeTransporter() {
    // Use Gmail as primary with multiple configuration options
    const config = {
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: parseInt(process.env.SMTP_PORT) || 587,
      secure: false,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
      tls: {
        rejectUnauthorized: false
      },
      // Optimized timeouts for Render
      connectionTimeout: 30000, // Increased to 30 seconds
      greetingTimeout: 30000,   // Increased to 30 seconds  
      socketTimeout: 30000,     // Increased to 30 seconds
      // Additional reliability settings
      pool: true, // Use connection pooling
      maxConnections: 5,
      maxMessages: 100,
    };

    console.log("SMTP Configuration:", {
      host: config.host,
      port: config.port,
      user: config.auth.user,
      pass: config.auth.pass ? "******" : "NOT SET",
    });

    this.transporter = nodemailer.createTransport(config);
    
    // Handle transporter events for better debugging
    this.transporter.on('idle', () => {
      console.log('Email transporter is idle');
    });

    this.transporter.on('error', (error) => {
      console.error('Email transporter error:', error);
    });
  }

  async sendOTPEmail(email: string, otp: string) {
    const mailOptions = {
      from: process.env.SMTP_USER,
      to: email,
      subject: 'Your OTP Verification Code - NeuroSense',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #2563eb;">NeuroSense OTP Verification</h1>
          <p>Hello,</p>
          <p>Your OTP verification code is:</p>
          <div style="background-color: #f3f4f6; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px;">
            <h2 style="color: #059669; margin: 0; font-size: 32px;">${otp}</h2>
          </div>
          <p>This code will expire in <strong>10 minutes</strong>.</p>
          <p>If you didn't request this code, please ignore this email.</p>
          <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 20px 0;">
          <p style="color: #6b7280; font-size: 14px;">NeuroSense - Cerebral Palsy Monitoring System</p>
        </div>
      `,
    };
    
    try {
      console.log(`Attempting to send OTP email to ${email}`);
      
      // Verify connection before sending
      await this.ensureConnection();
      
      const info = await this.transporter.sendMail(mailOptions);
      console.log(`Email sent successfully: ${info.messageId}`);
      
      return { 
        success: true, 
        message: 'OTP sent successfully', 
        messageId: info.messageId 
      };
    } catch (error) {
      console.error("Failed to send email:", error);
      
      // Try to recreate transporter if connection failed
      if (error.code === 'ECONNECTION' || error.code === 'ETIMEDOUT') {
        console.log('Recreating transporter due to connection error...');
        this.initializeTransporter();
      }
      
      return { 
        success: false, 
        message: `Failed to send email: ${error.message}`,
        errorCode: error.code 
      };
    }
  }

  async sendForgotPasswordEmail(email: string, newPassword: string) {
    const mailOptions = {
      from: process.env.SMTP_USER,
      to: email,
      subject: 'Password Reset - NeuroSense',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #2563eb;">Password Reset</h1>
          <p>Hello,</p>
          <p>Your password has been reset. Here is your new temporary password:</p>
          <div style="background-color: #fef3c7; padding: 15px; margin: 20px 0; border-radius: 8px; border-left: 4px solid #d97706;">
            <strong style="color: #92400e;">${newPassword}</strong>
          </div>
          <p><strong>Important:</strong> Please change your password immediately after logging in.</p>
          <p>If you didn't request this password reset, please contact support immediately.</p>
          <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 20px 0;">
          <p style="color: #6b7280; font-size: 14px;">NeuroSense - Cerebral Palsy Monitoring System</p>
        </div>
      `,
    };

    try {
      console.log(`Attempting to send password reset email to ${email}`);
      
      // Verify connection before sending
      await this.ensureConnection();
      
      const info = await this.transporter.sendMail(mailOptions);
      console.log(`Password reset email sent successfully: ${info.messageId}`);
      
      return { 
        success: true, 
        message: 'New password sent successfully',
        messageId: info.messageId 
      };
    } catch (error) {
      console.error('Password reset email sending error:', error);
      
      // Try to recreate transporter if connection failed
      if (error.code === 'ECONNECTION' || error.code === 'ETIMEDOUT') {
        console.log('Recreating transporter due to connection error...');
        this.initializeTransporter();
      }
      
      return { 
        success: false, 
        message: `Failed to send password reset email: ${error.message}`,
        errorCode: error.code 
      };
    }
  }

  private async ensureConnection() {
    try {
      // Verify connection is still alive
      if (!this.transporter.verify) {
        return true;
      }
      
      const isConnected = await this.transporter.verify();
      console.log('Email connection verified:', isConnected);
      return isConnected;
    } catch (error) {
      console.log('Email connection verification failed, recreating transporter...');
      this.initializeTransporter();
      return false;
    }
  }

  async onModuleInit() {
    try {
      console.log("Verifying email connection on startup...");
      await this.ensureConnection();
      console.log("Email service is ready to send emails");
    } catch (error) {
      console.error("Failed to connect to email server on startup:", error);
      console.log("Email service will attempt to connect when needed");
    }
  }

  // Additional method for testing email connectivity
  async testConnection() {
    try {
      const isConnected = await this.ensureConnection();
      return {
        success: isConnected,
        message: isConnected ? 'Email connection is active' : 'Email connection failed',
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        success: false,
        message: `Connection test failed: ${error.message}`,
        timestamp: new Date().toISOString()
      };
    }
  }
}
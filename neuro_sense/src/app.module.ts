import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from './authentication/auth.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    MongooseModule.forRoot(
      process.env.MONGODB_URI || 'mongodb+srv://adikanathniel2_db_user:x4ZwKOJhstnkyorA@cluster5.3hprnwe.mongodb.net/?appName=Cluster5 ',
    ),
    AuthModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}


// adikanathniel2_db_user   - db name
// x4ZwKOJhstnkyorA         - db password
// mongodb+srv://adikanathniel2_db_user:x4ZwKOJhstnkyorA@cluster5.3hprnwe.mongodb.net/?appName=Cluster5 
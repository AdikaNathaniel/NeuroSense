// src/facilities/facility.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { FacilityController } from './facility.controller';
import { FacilityService } from './facility.service';
import { Facility, FacilitySchema } from 'src/shared/schema/facility.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Facility.name, schema: FacilitySchema },
    ]),
  ],
  controllers: [FacilityController],
  providers: [FacilityService],
  exports: [FacilityService],
})
export class FacilityModule {}
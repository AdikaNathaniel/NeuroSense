// src/facilities/facility.controller.ts
import {
  Controller,
  Get,
  Post,
  Body,
  Put,
  Param,
  Delete,
  Query,
  UsePipes,
  ValidationPipe,
  HttpStatus,
  HttpCode,
} from '@nestjs/common';
import { FacilityService } from './facility.service';
import { CreateFacilityDto } from 'src/users/dto/create-facility.dto';
import { UpdateFacilityDto } from 'src/users/dto/update-facility.dto';
import { FilterFacilityDto } from 'src/users/dto/filter-facility.dto';
import { Facility } from 'src/shared/schema/facility.schema';

@Controller('facilities')
export class FacilityController {
  constructor(private readonly facilityService: FacilityService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @UsePipes(new ValidationPipe({ transform: true }))
  async create(@Body() createFacilityDto: CreateFacilityDto): Promise<Facility> {
    return this.facilityService.create(createFacilityDto);
  }

  @Get()
  @UsePipes(new ValidationPipe({ transform: true }))
  async findAll(@Query() filterDto: FilterFacilityDto): Promise<{
    facilities: Facility[];
    total: number;
    page: number;
    limit: number;
  }> {
    return this.facilityService.findAll(filterDto);
  }

  @Get('search')
  async search(@Query('q') query: string): Promise<Facility[]> {
    return this.facilityService.searchFacilities(query);
  }

  @Get('stats')
  async getStats(): Promise<any> {
    return this.facilityService.getFacilityStats();
  }

  @Get(':facilityName')
  async findOne(@Param('facilityName') facilityName: string): Promise<Facility> {
    return this.facilityService.findOne(facilityName);
  }

  @Put(':facilityName')
  @UsePipes(new ValidationPipe({ transform: true }))
  async update(
    @Param('facilityName') facilityName: string,
    @Body() updateFacilityDto: UpdateFacilityDto,
  ): Promise<Facility> {
    return this.facilityService.update(facilityName, updateFacilityDto);
  }

  @Delete(':facilityName')
  @HttpCode(HttpStatus.OK)
  async remove(@Param('facilityName') facilityName: string): Promise<{ message: string }> {
    return this.facilityService.remove(facilityName);
  }
}
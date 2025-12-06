// src/facilities/facility.service.ts
import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Facility } from 'src/shared/schema/facility.schema';
import { CreateFacilityDto } from 'src/users/dto/create-facility.dto';
import { UpdateFacilityDto } from 'src/users/dto/update-facility.dto';
import { FilterFacilityDto } from 'src/users/dto/filter-facility.dto';

@Injectable()
export class FacilityService {
  constructor(
    @InjectModel(Facility.name) private facilityModel: Model<Facility>,
  ) {}

  async create(createFacilityDto: CreateFacilityDto): Promise<Facility> {
    try {
      // Check if facility already exists
      const existingFacility = await this.facilityModel.findOne({
        facilityName: createFacilityDto.facilityName,
      });

      if (existingFacility) {
        throw new BadRequestException('Facility with this name already exists');
      }

    //   // Set specialization to Cerebral Palsy by default if not provided
    //   if (!createFacilityDto.specialization) {
    //     createFacilityDto.specialization = 'Cerebral Palsy Rehabilitation';
    //   }

      const createdFacility = new this.facilityModel(createFacilityDto);
      return createdFacility.save();
    } catch (error) {
      if (error.code === 11000) {
        throw new BadRequestException('Facility with this name already exists');
      }
      throw error;
    }
  }

  async findAll(filterDto: FilterFacilityDto = {}): Promise<{
    facilities: Facility[];
    total: number;
    page: number;
    limit: number;
  }> {
    const { 
      search, 
      city, 
      state, 
      country, 
      isActive,
      page = 1, 
      limit = 10 
    } = filterDto;

    const query: any = {};

    // Build search query
    if (search) {
      query.$or = [
        { facilityName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { 'location.city': { $regex: search, $options: 'i' } },
      ];
    }

    // Filter by location
    if (city) query['location.city'] = { $regex: city, $options: 'i' };
    if (state) query['location.state'] = { $regex: state, $options: 'i' };
    if (country) query['location.country'] = { $regex: country, $options: 'i' };
    
    // Filter by active status
    if (isActive !== undefined) query.isActive = isActive;

    const skip = (page - 1) * limit;

    const [facilities, total] = await Promise.all([
      this.facilityModel
        .find(query)
        .skip(skip)
        .limit(limit)
        .sort({ createdAt: -1 })
        .exec(),
      this.facilityModel.countDocuments(query).exec(),
    ]);

    return {
      facilities,
      total,
      page,
      limit,
    };
  }

  async findOne(facilityName: string): Promise<Facility> {
    const facility = await this.facilityModel.findOne({ 
      facilityName: { $regex: new RegExp(`^${facilityName}$`, 'i') } 
    }).exec();

    if (!facility) {
      throw new NotFoundException(`Facility with name "${facilityName}" not found`);
    }

    return facility;
  }

  async update(facilityName: string, updateFacilityDto: UpdateFacilityDto): Promise<Facility> {
    const facility = await this.facilityModel.findOne({ 
      facilityName: { $regex: new RegExp(`^${facilityName}$`, 'i') } 
    });

    if (!facility) {
      throw new NotFoundException(`Facility with name "${facilityName}" not found`);
    }

    // Prevent updating facility name if it's being changed to an existing one
    if (updateFacilityDto.facilityName && updateFacilityDto.facilityName !== facilityName) {
      const existingFacility = await this.facilityModel.findOne({
        facilityName: updateFacilityDto.facilityName,
      });

      if (existingFacility) {
        throw new BadRequestException('Facility with this name already exists');
      }
    }

    Object.assign(facility, updateFacilityDto);
    return facility.save();
  }

  async remove(facilityName: string): Promise<{ message: string }> {
    const result = await this.facilityModel.deleteOne({ 
      facilityName: { $regex: new RegExp(`^${facilityName}$`, 'i') } 
    });

    if (result.deletedCount === 0) {
      throw new NotFoundException(`Facility with name "${facilityName}" not found`);
    }

    return { message: `Facility "${facilityName}" deleted successfully` };
  }

  async searchFacilities(query: string): Promise<Facility[]> {
    return this.facilityModel.find({
      $or: [
        { facilityName: { $regex: query, $options: 'i' } },
        { 'location.city': { $regex: query, $options: 'i' } },
        { 'location.state': { $regex: query, $options: 'i' } }
      ],
      isActive: true,
    }).limit(10).exec();
  }

  async getFacilityStats(): Promise<any> {
    const stats = await this.facilityModel.aggregate([
      {
        $group: {
          _id: '$location.country',
          count: { $sum: 1 },
          activeCount: {
            $sum: { $cond: [{ $eq: ['$isActive', true] }, 1, 0] },
          },
        },
      },
      { $sort: { count: -1 } },
    ]);

    const total = await this.facilityModel.countDocuments();
    const active = await this.facilityModel.countDocuments({ isActive: true });

    return {
      total,
      active,
      inactive: total - active,
      byCountry: stats,
    };
  }
}
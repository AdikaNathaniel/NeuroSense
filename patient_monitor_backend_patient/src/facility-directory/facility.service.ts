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

  /**
   * Normalizes facility name by:
   * 1. Replacing multiple spaces with single space
   * 2. Trimming whitespace from beginning and end
   * 3. Normalizing spaces around parentheses
   */
  private normalizeFacilityName(name: string): string {
    if (!name) return name;
    
    // Replace multiple spaces with single space and trim
    let normalized = name.replace(/\s+/g, ' ').trim();
    
    // Normalize spaces around parentheses
    normalized = normalized.replace(/\s*\(\s*/g, ' (');  // Ensure single space before (
    normalized = normalized.replace(/\s*\)\s*/g, ') ');  // Ensure single space after )
    normalized = normalized.replace(/\s+/g, ' ').trim(); // Clean up any extra spaces
    
    return normalized;
  }

  /**
   * URL decodes and normalizes a facility name for searching
   */
  private prepareSearchName(facilityName: string): string {
    try {
      // Decode URL-encoded characters
      const decodedName = decodeURIComponent(facilityName);
      // Normalize the name for consistent comparison
      return this.normalizeFacilityName(decodedName);
    } catch (error) {
      // If decoding fails, use the original name
      return this.normalizeFacilityName(facilityName);
    }
  }

  /**
   * Escapes special regex characters in a string
   */
  private escapeRegex(str: string): string {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  /**
   * Finds a facility by name using multiple fallback strategies
   * Strategy 1: Exact normalized match (case-insensitive)
   * Strategy 2: Flexible whitespace match
   * Strategy 3: Fetch all and compare in-memory (last resort)
   */
  private async findFacilityByName(facilityName: string): Promise<Facility | null> {
    // Prepare the search name (decode URL and normalize)
    const searchName = this.prepareSearchName(facilityName);
    
    // Strategy 1: Try exact match with escaped regex
    const escapedName = this.escapeRegex(searchName);
    let facility = await this.facilityModel.findOne({ 
      facilityName: { $regex: new RegExp(`^${escapedName}$`, 'i') } 
    }).exec();

    if (facility) {
      return facility;
    }

    // Strategy 2: Try flexible whitespace matching
    const flexiblePattern = `^\\s*${escapedName.replace(/\s+/g, '\\s+')}\\s*$`;
    facility = await this.facilityModel.findOne({ 
      facilityName: { $regex: new RegExp(flexiblePattern, 'i') } 
    }).exec();

    if (facility) {
      return facility;
    }

    // Strategy 3: Fetch all facilities and compare in-memory (case-insensitive)
    // This is a last resort for edge cases
    const normalizedSearchLower = searchName.toLowerCase();
    const allFacilities = await this.facilityModel.find().exec();
    
    facility = allFacilities.find(f => {
      const normalizedFacilityName = this.normalizeFacilityName(f.facilityName).toLowerCase();
      return normalizedFacilityName === normalizedSearchLower;
    });

    if (facility) {
      return facility;
    }

    // Strategy 4: Try partial match (contains) as absolute last resort
    facility = allFacilities.find(f => {
      const normalizedFacilityName = this.normalizeFacilityName(f.facilityName).toLowerCase();
      return normalizedFacilityName.includes(normalizedSearchLower) || 
             normalizedSearchLower.includes(normalizedFacilityName);
    });

    return facility || null;
  }

  async create(createFacilityDto: CreateFacilityDto): Promise<Facility> {
    try {
      // Normalize facility name before saving
      createFacilityDto.facilityName = this.normalizeFacilityName(
        createFacilityDto.facilityName
      );

      // Check if facility already exists (with normalized name)
      const escapedName = this.escapeRegex(createFacilityDto.facilityName);
      const existingFacility = await this.facilityModel.findOne({
        facilityName: { $regex: new RegExp(`^${escapedName}$`, 'i') },
      });

      if (existingFacility) {
        throw new BadRequestException('Facility with this name already exists');
      }

      // Normalize location fields as well
      if (createFacilityDto.location) {
        if (createFacilityDto.location.address) {
          createFacilityDto.location.address = this.normalizeFacilityName(
            createFacilityDto.location.address
          );
        }
        if (createFacilityDto.location.city) {
          createFacilityDto.location.city = this.normalizeFacilityName(
            createFacilityDto.location.city
          );
        }
        if (createFacilityDto.location.state) {
          createFacilityDto.location.state = this.normalizeFacilityName(
            createFacilityDto.location.state
          );
        }
        if (createFacilityDto.location.country) {
          createFacilityDto.location.country = this.normalizeFacilityName(
            createFacilityDto.location.country
          );
        }
      }

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
      const normalizedSearch = this.normalizeFacilityName(search);
      const escapedSearch = this.escapeRegex(normalizedSearch);
      query.$or = [
        { facilityName: { $regex: escapedSearch, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { 'location.city': { $regex: escapedSearch, $options: 'i' } },
      ];
    }

    // Filter by location
    if (city) {
      const normalizedCity = this.normalizeFacilityName(city);
      const escapedCity = this.escapeRegex(normalizedCity);
      query['location.city'] = { $regex: escapedCity, $options: 'i' };
    }
    if (state) {
      const normalizedState = this.normalizeFacilityName(state);
      const escapedState = this.escapeRegex(normalizedState);
      query['location.state'] = { $regex: escapedState, $options: 'i' };
    }
    if (country) {
      const normalizedCountry = this.normalizeFacilityName(country);
      const escapedCountry = this.escapeRegex(normalizedCountry);
      query['location.country'] = { $regex: escapedCountry, $options: 'i' };
    }
    
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
    const facility = await this.findFacilityByName(facilityName);

    if (!facility) {
      throw new NotFoundException(`Facility with name "${facilityName}" not found`);
    }

    return facility;
  }

  async update(facilityName: string, updateFacilityDto: UpdateFacilityDto): Promise<Facility> {
    const facility = await this.findFacilityByName(facilityName);

    if (!facility) {
      throw new NotFoundException(`Facility with name "${facilityName}" not found`);
    }

    // Normalize the new facility name if provided
    if (updateFacilityDto.facilityName) {
      updateFacilityDto.facilityName = this.normalizeFacilityName(
        updateFacilityDto.facilityName
      );
      
      // Prevent updating facility name if it's being changed to an existing one
      if (updateFacilityDto.facilityName !== facility.facilityName) {
        const escapedName = this.escapeRegex(updateFacilityDto.facilityName);
        const existingFacility = await this.facilityModel.findOne({
          facilityName: { $regex: new RegExp(`^${escapedName}$`, 'i') },
        });

        if (existingFacility) {
          throw new BadRequestException('Facility with this name already exists');
        }
      }
    }

    // Normalize location fields if provided
    if (updateFacilityDto.location) {
      if (updateFacilityDto.location.address) {
        updateFacilityDto.location.address = this.normalizeFacilityName(
          updateFacilityDto.location.address
        );
      }
      if (updateFacilityDto.location.city) {
        updateFacilityDto.location.city = this.normalizeFacilityName(
          updateFacilityDto.location.city
        );
      }
      if (updateFacilityDto.location.state) {
        updateFacilityDto.location.state = this.normalizeFacilityName(
          updateFacilityDto.location.state
        );
      }
      if (updateFacilityDto.location.country) {
        updateFacilityDto.location.country = this.normalizeFacilityName(
          updateFacilityDto.location.country
        );
      }
    }

    Object.assign(facility, updateFacilityDto);
    return facility.save();
  }

  async remove(facilityName: string): Promise<{ message: string }> {
    const facility = await this.findFacilityByName(facilityName);

    if (!facility) {
      throw new NotFoundException(`Facility with name "${facilityName}" not found`);
    }

    await this.facilityModel.deleteOne({ _id: facility._id });

    return { message: `Facility "${facility.facilityName}" deleted successfully` };
  }

  async searchFacilities(query: string): Promise<Facility[]> {
    const normalizedQuery = this.normalizeFacilityName(query);
    const escapedQuery = this.escapeRegex(normalizedQuery);
    
    return this.facilityModel.find({
      $or: [
        { facilityName: { $regex: escapedQuery, $options: 'i' } },
        { 'location.city': { $regex: escapedQuery, $options: 'i' } },
        { 'location.state': { $regex: escapedQuery, $options: 'i' } }
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

  // Optional: Add ID-based methods for better API design
  async findById(id: string): Promise<Facility> {
    const facility = await this.facilityModel.findById(id).exec();

    if (!facility) {
      throw new NotFoundException(`Facility with ID "${id}" not found`);
    }

    return facility;
  }

  async updateById(id: string, updateFacilityDto: UpdateFacilityDto): Promise<Facility> {
    // Normalize the new facility name if provided
    if (updateFacilityDto.facilityName) {
      updateFacilityDto.facilityName = this.normalizeFacilityName(
        updateFacilityDto.facilityName
      );
      
      // Check if new name already exists
      const escapedName = this.escapeRegex(updateFacilityDto.facilityName);
      const existingFacility = await this.facilityModel.findOne({
        facilityName: { $regex: new RegExp(`^${escapedName}$`, 'i') },
        _id: { $ne: id }, // Exclude current facility
      });

      if (existingFacility) {
        throw new BadRequestException('Facility with this name already exists');
      }
    }

    const facility = await this.facilityModel.findByIdAndUpdate(
      id,
      { $set: updateFacilityDto },
      { new: true, runValidators: true }
    ).exec();

    if (!facility) {
      throw new NotFoundException(`Facility with ID "${id}" not found`);
    }

    return facility;
  }

  async removeById(id: string): Promise<{ message: string }> {
    const result = await this.facilityModel.findByIdAndDelete(id).exec();

    if (!result) {
      throw new NotFoundException(`Facility with ID "${id}" not found`);
    }

    return { message: `Facility deleted successfully` };
  }
}
import { Controller, Post, UseGuards, Get, Body } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { SumsubService } from './sumsub.service';
import { GetUser } from '../auth/get-user.decorator';
import { User } from '../auth/entities/user.entity';

@Controller('kyc')
export class SumsubController {
  constructor(private readonly sumsubService: SumsubService) {}

  @Post('access-token')
  @UseGuards(JwtAuthGuard)
  async generateAccessToken(@GetUser() user: User) {
    try {
      const token = await this.sumsubService.generateAccessToken(user.id);
      return { token };
    } catch (error) {
      console.error('Error generating access token:', error);
      throw error;
    }
  }

  @Post('webhook')
  async handleWebhook(@Body() payload: any) {
    return this.sumsubService.handleWebhook(payload);
  }
} 
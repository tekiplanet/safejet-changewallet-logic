import { Controller, Post, Get, Param, Body, UseGuards, Request, Query, HttpException, HttpStatus } from '@nestjs/common';
import { WalletService } from './wallet.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { GetUser } from '../auth/get-user.decorator';
import { User } from '../auth/entities/user.entity';
import { CreateWalletDto } from './dto/create-wallet.dto';

@Controller('wallets')
@UseGuards(JwtAuthGuard)
export class WalletController {
  constructor(private readonly walletService: WalletService) {}

  @Get('balances')
  async getBalances(
    @GetUser('id') userId: string,
    @Query('type') type?: string,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.walletService.getBalances(userId, type, {
      page: page || 1,
      limit: limit || 20,
    });
  }

  @Post()
  async createWallet(
    @GetUser() user: User,
    @Body() createWalletDto: CreateWalletDto,
  ) {
    return this.walletService.createWallet(user.id, createWalletDto);
  }

  @Get()
  async getWallets(@GetUser() user: User) {
    return this.walletService.getWallets(user.id);
  }

  @Get(':id')
  async getWallet(
    @GetUser() user: User,
    @Param('id') walletId: string,
  ) {
    return this.walletService.getWallet(user.id, walletId);
  }

  @Post('test-create')
  async testCreateWallet(
    @GetUser() user: User,
    @Body() createWalletDto: CreateWalletDto,
  ) {
    try {
      const wallet = await this.walletService.createWallet(user.id, createWalletDto);
      return {
        success: true,
        wallet: {
          id: wallet.id,
          blockchain: wallet.blockchain,
          address: wallet.address,
          status: wallet.status,
        },
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
      };
    }
  }
} 
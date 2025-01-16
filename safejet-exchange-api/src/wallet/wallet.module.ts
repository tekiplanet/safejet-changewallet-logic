import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WalletService } from './wallet.service';
import { WalletController } from './wallet.controller';
import { KeyManagementService } from './key-management.service';
import { Wallet } from './entities/wallet.entity';
import { WalletKey } from './entities/wallet-key.entity';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Wallet, WalletKey]),
    ConfigModule,
    forwardRef(() => AuthModule),
  ],
  providers: [WalletService, KeyManagementService],
  controllers: [WalletController],
  exports: [WalletService],
})
export class WalletModule {} 
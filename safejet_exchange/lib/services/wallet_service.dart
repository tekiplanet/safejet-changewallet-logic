import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../services/service_locator.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/coin.dart';

class WalletService {
  late final Dio _dio;
  final storage = const FlutterSecureStorage();
  final AuthService _authService = getIt<AuthService>();
  final _cache = <String, CacheEntry>{};
  final _cacheDuration = const Duration(minutes: 5);

  WalletService() {
    final baseUrl = _authService.baseUrl.replaceAll('/auth', '');
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'accessToken');
          print('Request URL: ${options.baseUrl}${options.path}');
          print('Request Headers: ${options.headers}');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          print('Error Response: ${error.response?.data}');
          print('Error Status Code: ${error.response?.statusCode}');
          print('Error Headers: ${error.response?.headers}');
          
          if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.unknown) {
            RequestOptions requestOptions = error.requestOptions;
            
            try {
              print('Retrying request to: ${requestOptions.path}');
              final response = await _dio.request(
                requestOptions.path,
                data: requestOptions.data,
                queryParameters: requestOptions.queryParameters,
                options: Options(
                  method: requestOptions.method,
                  headers: requestOptions.headers,
                ),
              );
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getBalances({
    String? type,
    String? currency,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/wallets/balances',
        queryParameters: {
          if (type != null) 'type': type,
          'page': page,
          'limit': limit,
        },
      );

      print('\n=== Raw Response Data ===');
      print(response.data);
      
      final balances = response.data['balances'] as List<dynamic>;
      balances.forEach((balance) {
        final token = balance['token'] as Map<String, dynamic>;
        final networks = balance['networks'] as List<dynamic>;
        
        print('\n=== Token Balance ===');
        print('Symbol: ${token['symbol']}');
        print('Type: ${balance['type']}');
        
        // Process networks with new structure
        if (networks != null) {
          print('\nNetwork Breakdown:');
          networks.forEach((network) {
            print('  ${network['blockchain']} (${network['networkVersion']}): '
                '${_formatBalance(network['balance'].toString(), token['decimals'])}');
          });
        }
      });

      return response.data;
    } catch (e) {
      print('Error in getBalances: $e');
      rethrow;
    }
  }

  String _formatBalance(String balance, int decimals) {
    try {
      // print('\nFormatting balance:');
      // print('Input balance: $balance');
      // print('Decimals: $decimals');
      
      double rawValue = double.parse(balance);
      // print('Parsed raw value: $rawValue');
      
      BigInt baseUnits = BigInt.from(rawValue * math.pow(10, decimals));
      // print('Base units: $baseUnits');
      
      BigInt wholePart = baseUnits ~/ BigInt.from(math.pow(10, decimals));
      BigInt fractionalPart = baseUnits % BigInt.from(math.pow(10, decimals));
      
      String fractionalStr = fractionalPart.toString().padLeft(decimals, '0');
      
      // Trim trailing zeros while keeping at least one decimal place
      while (fractionalStr.endsWith('0') && fractionalStr.length > 1) {
        fractionalStr = fractionalStr.substring(0, fractionalStr.length - 1);
      }
      
      String result = '$wholePart.$fractionalStr';
      print('Formatted result: $result');
      return result;
    } catch (e) {
      print('Error formatting balance: $balance with decimals: $decimals');
      print('Error details: $e');
      return '0.0';
    }
  }

  Future<Map<String, dynamic>> updateTokenMarketData(String tokenId, {String? timeframe}) async {
    try {
      final response = await _dio.post(
        '/wallets/token/$tokenId/market-data',
        queryParameters: timeframe != null ? {'timeframe': timeframe} : null,
      );
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
        };
      }
      
      return {
        'success': false,
        'message': 'Failed to update token market data',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getDepositAddress(
    String tokenId, {
    required String network,
    required String blockchain,
    required String version,
  }) async {
    try {
      final response = await _dio.get(
        '/wallets/deposit-address/$tokenId',
        queryParameters: {
          'network': network,
          'blockchain': blockchain,
          'version': version,
        },
      );
      return response.data;
    } catch (e) {
      debugPrint('Error getting deposit address: $e');
      rethrow;
    }
  }

  Future<List<Coin>> getAvailableCoins() async {
    try {
      final response = await _dio.get('/wallets/tokens/available');
      
      final List<dynamic> tokens = response.data['tokens'];
      return tokens.map((token) {
        final metadata = token['metadata'] as Map<String, dynamic>;
        final networks = List<Map<String, dynamic>>.from(token['networks']);
        
        // Deduplicate networks based on blockchain, version and network
        final uniqueNetworks = networks.fold<List<Map<String, dynamic>>>(
          [], 
          (unique, network) {
            if (!unique.any((n) => 
                n['blockchain'] == network['blockchain'] && 
                n['version'] == network['version'] &&
                n['network'] == network['network'])) {
              unique.add(network);
            }
            return unique;
          }
        );

        return Coin(
          id: token['id'],
          symbol: token['symbol'],
          name: token['name'],
          iconUrl: metadata['icon'],
          networks: uniqueNetworks.map((network) => Network(
            name: network['blockchain'],
            blockchain: network['blockchain'],
            version: network['version'],
            arrivalTime: network['arrivalTime'],
            network: network['network'],
            requiresMemo: network['requiredFields']?['memo'] ?? false,
            requiresTag: network['requiredFields']?['tag'] ?? false,
          )).toList(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting available coins: $e');
      rethrow;
    }
  }
}

class CacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final Duration validity;

  CacheEntry({
    required this.data,
    required this.timestamp,
    this.validity = const Duration(minutes: 1),
  });

  bool get isExpired => DateTime.now().difference(timestamp) > validity;
} 
import 'package:dio/dio.dart';

import '../../core/api_client.dart';

class AddressRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Map<String, dynamic>>> listAddresses() async {
    final resp = await _dio.get('/store-api/account/list-address');
    final data = resp.data;
    if (data is Map && data['elements'] is List) {
      return List<Map<String, dynamic>>.from(data['elements']);
    }
    // Some setups return raw array
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> address) async {
    final resp = await _dio.post('/store-api/account/address', data: address);
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<void> updateAddress(String addressId, Map<String, dynamic> address) async {
    await _dio.patch('/store-api/account/address/$addressId', data: address);
  }

  Future<void> deleteAddress(String addressId) async {
    await _dio.delete('/store-api/account/address/$addressId');
  }

  Future<void> setDefaultBilling(String addressId) async {
    await _dio.patch('/store-api/account/address/default-billing/$addressId');
  }

  Future<void> setDefaultShipping(String addressId) async {
    await _dio.patch('/store-api/account/address/default-shipping/$addressId');
  }
}



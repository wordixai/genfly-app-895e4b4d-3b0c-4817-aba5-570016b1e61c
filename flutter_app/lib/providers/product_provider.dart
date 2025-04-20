
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/product.dart';
import '../utils/api_exception.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _topProducts = [];
  Product? _product;
  bool _isLoading = false;
  String? _error;
  final String baseUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:5000/api';

  List<Product> get products => [..._products];
  List<Product> get topProducts => [..._topProducts];
  Product? get product => _product;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts({String? keyword, int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = '$baseUrl/products?pageNumber=$page';
      if (keyword != null && keyword.isNotEmpty) {
        url += '&keyword=$keyword';
      }

      final response = await http.get(Uri.parse(url));
      final responseData = json.decode(response.body);

      if (response.statusCode >= 400) {
        throw ApiException(
          message: responseData['message'] ?? 'Failed to fetch products',
          statusCode: response
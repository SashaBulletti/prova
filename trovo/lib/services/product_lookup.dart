import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cerca il nome di un prodotto dal codice a barre su Open Food Facts,
/// un database libero e gratuito con milioni di prodotti (anche italiani).
/// Restituisce null se non lo trova o se non c'è internet.
Future<String?> lookupProductName(String barcode, {required bool italian}) async {
  final code = barcode.trim();
  if (!RegExp(r'^\d{6,14}$').hasMatch(code)) return null;
  final uri = Uri.https('world.openfoodfacts.org', '/api/v2/product/$code.json', {
    'fields': 'product_name,product_name_it,product_name_en,generic_name,brands',
  });
  try {
    final res = await http
        .get(uri, headers: {'User-Agent': 'Trovo/1.0 (Flutter app)'})
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (data is! Map || data['status'] != 1 || data['product'] is! Map) return null;
    final p = data['product'] as Map;
    String? pick(String key) {
      final v = p[key];
      return (v is String && v.trim().isNotEmpty) ? v.trim() : null;
    }

    final name = (italian ? pick('product_name_it') : pick('product_name_en')) ??
        pick('product_name') ??
        pick('generic_name');
    if (name == null) return null;
    final brand = pick('brands')?.split(',').first.trim();
    if (brand != null && brand.isNotEmpty && !name.toLowerCase().contains(brand.toLowerCase())) {
      return '$name ($brand)';
    }
    return name;
  } catch (e) {
    debugPrint('Trovo: ricerca prodotto non riuscita ($e)');
    return null;
  }
}

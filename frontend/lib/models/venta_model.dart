import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/venta_model.dart';  // Corrected path from services to models

class Venta {
  final String? id; // El ID que genera MongoDB
  final String userId;
  final DateTime? saleDate;
  final List<VentaItem> items;
  final String status;
  final String paymentMethod;
  final double totalAmount;

  Venta({
    this.id,
    required this.userId,
    this.saleDate,
    required this.items,
    this.status = 'completed',
    required this.paymentMethod,
    required this.totalAmount,
   
  });

  // Convierte el objeto a JSON para enviarlo a Railway (POST)
  Map<String, dynamic> toJson() {
    return {
      "user_id": userId,
      "status": status,
      "payment_method": paymentMethod,
      "items": items.map((item) => item.toJson()).toList(),
      // El total se puede enviar o dejar que el servidor lo calcule
      "total_amount": totalAmount,
    };
  }

  // Convierte el JSON de Railway a objeto Dart (para HU16: Consultar ventas)
  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json['_id'],
      userId: json['user_id'],
      saleDate: DateTime.parse(json['sale_date']),
      status: json['status'],
      paymentMethod: json['payment_method'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      items: (json['items'] as List)
          .map((i) => VentaItem.fromJson(i))
          .toList(),
    );
  }
}

class VentaItem {
  final int productId;
  final String name;
  final double priceAtSale;
  final int quantity;

  VentaItem({
    required this.productId,
    required this.name,
    required this.priceAtSale,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      "product_id": productId,
      "name": name,
      "price_at_sale": priceAtSale,
      "quantity": quantity,
    };
  }

  factory VentaItem.fromJson(Map<String, dynamic> json) {
    return VentaItem(
      productId: json['product_id'],
      name: json['name'],
      priceAtSale: (json['price_at_sale'] as num).toDouble(),
      quantity: json['quantity'],
    );
  }
}
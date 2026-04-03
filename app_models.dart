import 'dart:convert';

import 'package:crypto/crypto.dart';

const String adminSecretCode = 'MPZ-ADMIN-2026';
const String storageKey = 'printer_shop_database_v1';
const String sessionKey = 'printer_shop_session_v1';
const String adminInboxId = 'admin';

enum UserRole { admin, customer }
enum OrderStatus { pending, accepted, completed, cancelled }
enum PaymentType { notSelected, online, offline }
enum NoticeStatus { unread, read }

String userRoleLabel(UserRole role) => role == UserRole.admin ? 'Admin' : 'Customer';
String orderStatusLabel(OrderStatus status) => status.name.toUpperCase();
String paymentTypeLabel(PaymentType paymentType) => paymentType.name == 'notSelected' ? 'NOT_SELECTED' : paymentType.name.toUpperCase();
String noticeStatusLabel(NoticeStatus status) => status.name.toUpperCase();
String formatCurrency(double amount) => 'Rs ${amount.toStringAsFixed(2)}';
String hashPassword(String password) => sha256.convert(utf8.encode(password)).toString();
String makeId(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}';
bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String formatDate(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String formatDateTime(DateTime date) {
  final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '${formatDate(date)} $hour:$minute $suffix';
}

class AppUser {
  AppUser({required this.id, required this.name, required this.phone, required this.email, required this.passwordHash, required this.role, required this.createdAt});
  final String id;
  final String name;
  final String phone;
  final String email;
  final String passwordHash;
  final UserRole role;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone, 'email': email, 'passwordHash': passwordHash, 'role': role.name, 'createdAt': createdAt.toIso8601String()};
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(id: json['id'] as String, name: json['name'] as String, phone: json['phone'] as String, email: json['email'] as String, passwordHash: json['passwordHash'] as String, role: UserRole.values.byName(json['role'] as String), createdAt: DateTime.parse(json['createdAt'] as String));
}

class PrintService {
  PrintService({required this.id, required this.name, required this.description, required this.price, required this.unit, required this.createdAt});
  final String id;
  final String name;
  final String description;
  final double price;
  final String unit;
  final DateTime createdAt;
  PrintService copyWith({String? name, String? description, double? price, String? unit}) => PrintService(id: id, name: name ?? this.name, description: description ?? this.description, price: price ?? this.price, unit: unit ?? this.unit, createdAt: createdAt);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'description': description, 'price': price, 'unit': unit, 'createdAt': createdAt.toIso8601String()};
  factory PrintService.fromJson(Map<String, dynamic> json) => PrintService(id: json['id'] as String, name: json['name'] as String, description: json['description'] as String, price: (json['price'] as num).toDouble(), unit: json['unit'] as String, createdAt: DateTime.parse(json['createdAt'] as String));
}

class OrderOptions {
  OrderOptions({required this.printMode, required this.paperSize, required this.notes});
  final String printMode;
  final String paperSize;
  final String notes;
  Map<String, dynamic> toJson() => {'printMode': printMode, 'paperSize': paperSize, 'notes': notes};
  factory OrderOptions.fromJson(Map<String, dynamic> json) => OrderOptions(printMode: json['printMode'] as String, paperSize: json['paperSize'] as String, notes: json['notes'] as String);
}

class PrintOrder {
  PrintOrder({required this.id, required this.userId, required this.serviceId, required this.fileName, required this.quantity, required this.options, required this.amount, required this.status, required this.paymentType, required this.createdAt});
  final String id;
  final String userId;
  final String serviceId;
  final String fileName;
  final int quantity;
  final OrderOptions options;
  final double amount;
  final OrderStatus status;
  final PaymentType paymentType;
  final DateTime createdAt;
  PrintOrder copyWith({OrderStatus? status, PaymentType? paymentType}) => PrintOrder(id: id, userId: userId, serviceId: serviceId, fileName: fileName, quantity: quantity, options: options, amount: amount, status: status ?? this.status, paymentType: paymentType ?? this.paymentType, createdAt: createdAt);
  Map<String, dynamic> toJson() => {'id': id, 'userId': userId, 'serviceId': serviceId, 'fileName': fileName, 'quantity': quantity, 'options': options.toJson(), 'amount': amount, 'status': status.name, 'paymentType': paymentType.name, 'createdAt': createdAt.toIso8601String()};
  factory PrintOrder.fromJson(Map<String, dynamic> json) => PrintOrder(id: json['id'] as String, userId: json['userId'] as String, serviceId: json['serviceId'] as String, fileName: json['fileName'] as String, quantity: (json['quantity'] as num).toInt(), options: OrderOptions.fromJson(Map<String, dynamic>.from(json['options'] as Map)), amount: (json['amount'] as num).toDouble(), status: OrderStatus.values.byName(json['status'] as String), paymentType: PaymentType.values.byName(json['paymentType'] as String), createdAt: DateTime.parse(json['createdAt'] as String));
}

class AppNotification {
  AppNotification({required this.id, required this.recipientId, required this.message, required this.status, required this.timestamp});
  final String id;
  final String recipientId;
  final String message;
  final NoticeStatus status;
  final DateTime timestamp;
  AppNotification copyWith({NoticeStatus? status}) => AppNotification(id: id, recipientId: recipientId, message: message, status: status ?? this.status, timestamp: timestamp);
  Map<String, dynamic> toJson() => {'id': id, 'recipientId': recipientId, 'message': message, 'status': status.name, 'timestamp': timestamp.toIso8601String()};
  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(id: json['id'] as String, recipientId: json['recipientId'] as String, message: json['message'] as String, status: NoticeStatus.values.byName(json['status'] as String), timestamp: DateTime.parse(json['timestamp'] as String));
}

class SessionData {
  SessionData({required this.userId, required this.createdAt});
  final String userId;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {'userId': userId, 'createdAt': createdAt.toIso8601String()};
  factory SessionData.fromJson(Map<String, dynamic> json) => SessionData(userId: json['userId'] as String, createdAt: DateTime.parse(json['createdAt'] as String));
}

class AppDatabase {
  AppDatabase({required this.users, required this.orders, required this.notifications, required this.services});
  List<AppUser> users;
  List<PrintOrder> orders;
  List<AppNotification> notifications;
  List<PrintService> services;
  factory AppDatabase.seed() {
    final now = DateTime.now();
    return AppDatabase(users: [], orders: [], notifications: [], services: [
      PrintService(id: makeId('svc'), name: 'Document Printing', description: 'Black and white or color printing for class notes, office files, and forms.', price: 5, unit: 'per copy', createdAt: now),
      PrintService(id: makeId('svc'), name: 'Photo Printing', description: 'Glossy and matte prints for events, portfolios, and framed photos.', price: 30, unit: 'per print', createdAt: now),
      PrintService(id: makeId('svc'), name: 'Binding and Finishing', description: 'Spiral binding, cover sheets, trimming, and finishing for project submissions.', price: 60, unit: 'per order', createdAt: now),
    ]);
  }
  Map<String, dynamic> toJson() => {'users': users.map((e) => e.toJson()).toList(), 'orders': orders.map((e) => e.toJson()).toList(), 'notifications': notifications.map((e) => e.toJson()).toList(), 'services': services.map((e) => e.toJson()).toList()};
  factory AppDatabase.fromJson(Map<String, dynamic> json) => AppDatabase(
    users: (json['users'] as List<dynamic>? ?? []).map((e) => AppUser.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    orders: (json['orders'] as List<dynamic>? ?? []).map((e) => PrintOrder.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    notifications: (json['notifications'] as List<dynamic>? ?? []).map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    services: (json['services'] as List<dynamic>? ?? []).map((e) => PrintService.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
  );
}

class DashboardStats {
  DashboardStats({required this.totalOrders, required this.pendingOrders, required this.completedOrders, required this.cancelledOrders, required this.onlineTotal, required this.offlineTotal, required this.totalRevenue, required this.totalCustomers});
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double onlineTotal;
  final double offlineTotal;
  final double totalRevenue;
  final int totalCustomers;
}
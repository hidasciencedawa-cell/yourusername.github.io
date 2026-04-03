import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_models.dart';

class AppRepository extends ChangeNotifier {
  AppRepository._(this._preferences, this._database, this._session);

  final SharedPreferences _preferences;
  AppDatabase _database;
  SessionData? _session;

  static Future<AppRepository> create() async {
    final preferences = await SharedPreferences.getInstance();
    final dbRaw = preferences.getString(storageKey);
    final sessionRaw = preferences.getString(sessionKey);
    final database = dbRaw == null ? AppDatabase.seed() : AppDatabase.fromJson(jsonDecode(dbRaw) as Map<String, dynamic>);
    final session = sessionRaw == null ? null : SessionData.fromJson(jsonDecode(sessionRaw) as Map<String, dynamic>);
    final repository = AppRepository._(preferences, database, session);
    await repository._persist();
    return repository;
  }

  AppUser? get currentUser {
    final session = _session;
    if (session == null) return null;
    try {
      return _database.users.firstWhere((user) => user.id == session.userId);
    } catch (_) {
      return null;
    }
  }

  List<PrintService> get services => List.unmodifiable(_database.services);
  List<AppUser> get customers => List.unmodifiable(_database.users.where((user) => user.role == UserRole.customer));

  Future<String?> register({required String name, required String phone, required String email, required String password, required String confirmPassword, required UserRole role, String secretCode = ''}) async {
    final cleanEmail = email.trim().toLowerCase();
    if ([name, phone, cleanEmail, password, confirmPassword].any((value) => value.trim().isEmpty)) return 'Please fill all required fields.';
    if (password != confirmPassword) return 'Passwords do not match.';
    if (role == UserRole.admin && secretCode.trim() != adminSecretCode) return 'Invalid admin secret code.';
    if (_database.users.any((user) => user.email == cleanEmail && user.role == role)) {
      return 'A ${userRoleLabel(role)} account with this email already exists.';
    }
    _database.users.add(AppUser(id: makeId('usr'), name: name.trim(), phone: phone.trim(), email: cleanEmail, passwordHash: hashPassword(password), role: role, createdAt: DateTime.now()));
    await _persistAndNotify();
    return null;
  }

  Future<String?> login({required String email, required String password, required UserRole role, String secretCode = ''}) async {
    final cleanEmail = email.trim().toLowerCase();
    final matching = _database.users.where((user) => user.email == cleanEmail && user.role == role);
    if (matching.isEmpty) return 'No ${userRoleLabel(role)} account found for this email.';
    final user = matching.first;
    if (user.passwordHash != hashPassword(password)) return 'Invalid password.';
    if (role == UserRole.admin && secretCode.trim() != adminSecretCode) return 'Invalid admin secret code.';
    _session = SessionData(userId: user.id, createdAt: DateTime.now());
    await _persistAndNotify();
    return null;
  }

  Future<void> logout() async {
    _session = null;
    await _persistAndNotify();
  }

  PrintService? serviceById(String id) {
    try { return _database.services.firstWhere((service) => service.id == id); } catch (_) { return null; }
  }

  AppUser? userById(String id) {
    try { return _database.users.firstWhere((user) => user.id == id); } catch (_) { return null; }
  }

  Future<String?> placeOrder({required String serviceId, required int quantity, required String printMode, required String paperSize, required String notes, required String fileName}) async {
    final user = currentUser;
    if (user == null || user.role != UserRole.customer) return 'Please login as a customer.';
    final service = serviceById(serviceId);
    if (service == null) return 'Selected service not found.';
    if (quantity <= 0) return 'Quantity must be at least 1.';
    _database.orders.insert(0, PrintOrder(id: makeId('ord'), userId: user.id, serviceId: service.id, fileName: fileName.trim(), quantity: quantity, options: OrderOptions(printMode: printMode, paperSize: paperSize, notes: notes.trim()), amount: service.price * quantity, status: OrderStatus.pending, paymentType: PaymentType.notSelected, createdAt: DateTime.now()));
    _addNotification(recipientId: adminInboxId, message: 'New order received from ${user.name} for ${service.name}.');
    await _persistAndNotify();
    return null;
  }

  Future<void> saveService({String? serviceId, required String name, required String description, required double price, required String unit}) async {
    if (serviceId == null) {
      _database.services.insert(0, PrintService(id: makeId('svc'), name: name.trim(), description: description.trim(), price: price, unit: unit.trim().isEmpty ? 'per order' : unit.trim(), createdAt: DateTime.now()));
    } else {
      final index = _database.services.indexWhere((service) => service.id == serviceId);
      if (index != -1) {
        _database.services[index] = _database.services[index].copyWith(name: name.trim(), description: description.trim(), price: price, unit: unit.trim().isEmpty ? 'per order' : unit.trim());
      }
    }
    await _persistAndNotify();
  }

  Future<void> deleteService(String serviceId) async {
    _database.services.removeWhere((service) => service.id == serviceId);
    await _persistAndNotify();
  }

  Future<void> deleteOrder(String orderId) async {
    _database.orders.removeWhere((order) => order.id == orderId);
    _database.notifications.removeWhere((notification) => notification.message.contains(orderId));
    await _persistAndNotify();
  }

  Future<void> deleteCustomer(String customerId) async {
    final customerOrderIds = _database.orders.where((order) => order.userId == customerId).map((order) => order.id).toList();
    _database.users.removeWhere((user) => user.id == customerId);
    _database.orders.removeWhere((order) => order.userId == customerId);
    _database.notifications.removeWhere((notification) {
      if (notification.recipientId == customerId) {
        return true;
      }
      return customerOrderIds.any(notification.message.contains);
    });
    await _persistAndNotify();
  }

  List<PrintOrder> ordersForCurrentUser() {
    final user = currentUser;
    if (user == null) return [];
    return _database.orders.where((order) => order.userId == user.id).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<PrintOrder> allOrders() => List<PrintOrder>.from(_database.orders)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> acceptOrder(String orderId) async => _updateOrder(orderId, status: OrderStatus.accepted);
  Future<void> cancelOrder(String orderId) async => _updateOrder(orderId, status: OrderStatus.cancelled);
  Future<void> completeOrder(String orderId, PaymentType paymentType) async => _updateOrder(orderId, status: OrderStatus.completed, paymentType: paymentType);

  Future<void> _updateOrder(String orderId, {required OrderStatus status, PaymentType? paymentType}) async {
    final index = _database.orders.indexWhere((order) => order.id == orderId);
    if (index == -1) return;
    final updated = _database.orders[index].copyWith(status: status, paymentType: paymentType ?? _database.orders[index].paymentType);
    _database.orders[index] = updated;
    final customer = userById(updated.userId);
    if (customer != null) {
      String message;
      switch (status) {
        case OrderStatus.pending: message = 'Your order ${updated.id} is pending.'; break;
        case OrderStatus.accepted: message = 'Your order ${updated.id} has been accepted.'; break;
        case OrderStatus.completed: message = 'Your order ${updated.id} has been completed with ${paymentTypeLabel(updated.paymentType)} payment.'; break;
        case OrderStatus.cancelled: message = 'Your order ${updated.id} has been cancelled.'; break;
      }
      _addNotification(recipientId: customer.id, message: message);
    }
    await _persistAndNotify();
  }

  List<AppNotification> notificationsForCurrentUser() {
    final user = currentUser;
    if (user == null) return [];
    final includeAdminInbox = user.role == UserRole.admin;
    return _database.notifications.where((notification) => notification.recipientId == user.id || (includeAdminInbox && notification.recipientId == adminInboxId)).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> markNotificationsRead() async {
    final user = currentUser;
    if (user == null) return;
    final includeAdminInbox = user.role == UserRole.admin;
    _database.notifications = _database.notifications.map((notification) {
      final matches = notification.recipientId == user.id || (includeAdminInbox && notification.recipientId == adminInboxId);
      return matches ? notification.copyWith(status: NoticeStatus.read) : notification;
    }).toList();
    await _persistAndNotify();
  }

  DashboardStats computeStats({DateTime? forDate}) {
    final sourceOrders = forDate == null ? _database.orders : _database.orders.where((order) => isSameDay(order.createdAt, forDate)).toList();
    final completed = sourceOrders.where((order) => order.status == OrderStatus.completed).toList();
    final pending = sourceOrders.where((order) => order.status == OrderStatus.pending || order.status == OrderStatus.accepted).length;
    final cancelled = sourceOrders.where((order) => order.status == OrderStatus.cancelled).length;
    final onlineTotal = completed.where((order) => order.paymentType == PaymentType.online).fold<double>(0, (sum, order) => sum + order.amount);
    final offlineTotal = completed.where((order) => order.paymentType == PaymentType.offline).fold<double>(0, (sum, order) => sum + order.amount);
    return DashboardStats(totalOrders: sourceOrders.length, pendingOrders: pending, completedOrders: completed.length, cancelledOrders: cancelled, onlineTotal: onlineTotal, offlineTotal: offlineTotal, totalRevenue: onlineTotal + offlineTotal, totalCustomers: customers.length);
  }

  int totalOrdersForCustomer(String customerId) => _database.orders.where((order) => order.userId == customerId).length;
  int completedOrdersForCustomer(String customerId) => _database.orders.where((order) => order.userId == customerId && order.status == OrderStatus.completed).length;

  void _addNotification({required String recipientId, required String message}) {
    _database.notifications.insert(0, AppNotification(id: makeId('not'), recipientId: recipientId, message: message, status: NoticeStatus.unread, timestamp: DateTime.now()));
  }

  Future<void> _persistAndNotify() async {
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _preferences.setString(storageKey, jsonEncode(_database.toJson()));
    if (_session == null) {
      await _preferences.remove(sessionKey);
    } else {
      await _preferences.setString(sessionKey, jsonEncode(_session!.toJson()));
    }
  }
}

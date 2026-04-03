import 'package:flutter/material.dart';

import '../app_repository.dart';
import '../models/app_models.dart';
import '../widgets/shared_widgets.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key, required this.repository});
  final AppRepository repository;
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final quantityController = TextEditingController(text: '1');
  final fileNameController = TextEditingController();
  final notesController = TextEditingController();
  String? selectedServiceId;
  String printMode = 'BLACK_AND_WHITE';
  String paperSize = 'A4';

  @override
  void initState() {
    super.initState();
    final services = widget.repository.services;
    if (services.isNotEmpty) selectedServiceId = services.first.id;
    quantityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    quantityController.dispose();
    fileNameController.dispose();
    notesController.dispose();
    super.dispose();
  }

  double get estimate {
    final service = widget.repository.serviceById(selectedServiceId ?? '');
    final quantity = int.tryParse(quantityController.text) ?? 1;
    if (service == null || quantity <= 0) return 0;
    return service.price * quantity;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.repository.currentUser!;
    final orders = widget.repository.ordersForCurrentUser();
    final notifications = widget.repository.notificationsForCurrentUser();
    final completed = orders.where((order) => order.status == OrderStatus.completed).length;
    final open = orders.where((order) => order.status == OrderStatus.pending || order.status == OrderStatus.accepted).length;
    final totalSpent = orders.where((order) => order.status == OrderStatus.completed).fold<double>(0, (sum, order) => sum + order.amount);

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Customer Dashboard', style: TextStyle(fontWeight: FontWeight.w800)),
          Text('${user.name} | ${user.email}', style: const TextStyle(fontSize: 12, color: Color(0xFF5B6B7F))),
        ]),
        actions: [TextButton(onPressed: widget.repository.logout, child: const Text('Logout')), const SizedBox(width: 12)],
      ),
      body: AnimatedBuilder(
        animation: widget.repository,
        builder: (context, _) {
          final services = widget.repository.services;
          selectedServiceId ??= services.isNotEmpty ? services.first.id : null;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ResponsiveSection(
                left: InfoHeroCard(kicker: 'Welcome back', title: 'Hello ${user.name}, your print desk is ready.', body: 'Place a new order, follow status changes, and keep a permanent record of every request.', pills: [StatPill(label: 'Total Orders', value: '${orders.length}'), StatPill(label: 'Open Orders', value: '$open'), StatPill(label: 'Completed', value: '$completed'), StatPill(label: 'Total Spent', value: formatCurrency(totalSpent))]),
                right: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Place a new order', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text('Choose a service, quantity, print options, and file reference.'),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(value: selectedServiceId, items: services.map((service) => DropdownMenuItem(value: service.id, child: Text('${service.name} - ${formatCurrency(service.price)} (${service.unit})'))).toList(), onChanged: (value) => setState(() => selectedServiceId = value), decoration: const InputDecoration(labelText: 'Service')),
                      const SizedBox(height: 14),
                      Row(children: [Expanded(child: TextField(controller: quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity'))), const SizedBox(width: 14), Expanded(child: DropdownButtonFormField<String>(value: paperSize, items: const ['A4', 'A3', 'Photo 4x6', 'Custom'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (value) => setState(() => paperSize = value ?? 'A4'), decoration: const InputDecoration(labelText: 'Paper Size')))]),
                      const SizedBox(height: 14),
                      Row(children: [Expanded(child: DropdownButtonFormField<String>(value: printMode, items: const [DropdownMenuItem(value: 'BLACK_AND_WHITE', child: Text('Black and White')), DropdownMenuItem(value: 'COLOR', child: Text('Color'))], onChanged: (value) => setState(() => printMode = value ?? 'BLACK_AND_WHITE'), decoration: const InputDecoration(labelText: 'Print Mode'))), const SizedBox(width: 14), Expanded(child: TextField(controller: fileNameController, decoration: const InputDecoration(labelText: 'File Name / Link')))]),
                      const SizedBox(height: 14),
                      TextField(controller: notesController, maxLines: 4, decoration: const InputDecoration(labelText: 'Order Notes')),
                      const SizedBox(height: 16),
                      Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: const Color(0xFFFFF7E8)), child: Text('Estimated total: ${formatCurrency(estimate)}', style: const TextStyle(fontWeight: FontWeight.w800))),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            final error = await widget.repository.placeOrder(serviceId: selectedServiceId ?? '', quantity: int.tryParse(quantityController.text) ?? 1, printMode: printMode, paperSize: paperSize, notes: notesController.text, fileName: fileNameController.text);
                            if (!context.mounted) return;
                            if (error != null) {
                              showAppSnackBar(context, error, isError: true);
                            } else {
                              quantityController.text = '1';
                              fileNameController.clear();
                              notesController.clear();
                              showAppSnackBar(context, 'Order placed successfully.');
                            }
                          },
                          child: const Text('Place Order'),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ResponsiveSection(
                left: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Available Services', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text('Current service list with descriptions and prices.'),
                      const SizedBox(height: 18),
                      ...services.map((service) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: const Color(0xFFFAFCFD), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [Expanded(child: Text(service.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))), Text(formatCurrency(service.price), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F766E)))]),
                              const SizedBox(height: 8),
                              Text(service.description),
                              const SizedBox(height: 8),
                              Chip(label: Text(service.unit)),
                            ]),
                          ),
                        ),
                      )),
                    ]),
                  ),
                ),
                right: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), SizedBox(height: 8), Text('Recent updates from the print shop.')])), TextButton(onPressed: () async { await widget.repository.markNotificationsRead(); if (context.mounted) showAppSnackBar(context, 'Notifications marked as read.'); }, child: const Text('Mark as read'))]),
                      const SizedBox(height: 18),
                      if (notifications.isEmpty) const EmptyPlaceholder(message: 'No notifications yet.') else ...notifications.take(8).map((note) => ListTile(contentPadding: EdgeInsets.zero, title: Text(note.message, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(formatDateTime(note.timestamp)), trailing: StatusBadge(label: noticeStatusLabel(note.status), color: note.status == NoticeStatus.unread ? const Color(0xFFF59E0B) : const Color(0xFF64748B))))
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Order History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('All your orders are kept permanently and remain available for future date filtering.'),
                    const SizedBox(height: 18),
                    if (orders.isEmpty) const EmptyPlaceholder(message: 'No orders yet. Your first order will appear here.') else ...orders.map((order) => OrderCard(order: order, serviceName: widget.repository.serviceById(order.serviceId)?.name ?? 'Removed service', customerName: user.name)),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../app_repository.dart';
import '../models/app_models.dart';
import '../widgets/shared_widgets.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, required this.repository});
  final AppRepository repository;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int currentIndex = 0;
  OrderStatus? orderFilter;
  DateTime reportDate = DateTime.now();
  String? editingServiceId;

  final serviceNameController = TextEditingController();
  final serviceDescriptionController = TextEditingController();
  final servicePriceController = TextEditingController();
  final serviceUnitController = TextEditingController();

  @override
  void dispose() {
    serviceNameController.dispose();
    serviceDescriptionController.dispose();
    servicePriceController.dispose();
    serviceUnitController.dispose();
    super.dispose();
  }

  void beginEditService(PrintService service) {
    setState(() {
      currentIndex = 3;
      editingServiceId = service.id;
      serviceNameController.text = service.name;
      serviceDescriptionController.text = service.description;
      servicePriceController.text = service.price.toStringAsFixed(2);
      serviceUnitController.text = service.unit;
    });
  }

  void resetServiceForm() {
    setState(() {
      editingServiceId = null;
      serviceNameController.clear();
      serviceDescriptionController.clear();
      servicePriceController.clear();
      serviceUnitController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.repository.currentUser!;
    final pages = [
      _OverviewPage(repository: widget.repository),
      _OrdersPage(
        repository: widget.repository,
        filter: orderFilter,
        onFilterChanged: (value) => setState(() => orderFilter = value),
      ),
      _CustomersPage(repository: widget.repository),
      _ServicesPage(
        repository: widget.repository,
        editingServiceId: editingServiceId,
        onEdit: beginEditService,
        onReset: resetServiceForm,
        serviceNameController: serviceNameController,
        serviceDescriptionController: serviceDescriptionController,
        servicePriceController: servicePriceController,
        serviceUnitController: serviceUnitController,
      ),
      _ReportsPage(
        repository: widget.repository,
        reportDate: reportDate,
        onDateChanged: (value) => setState(() => reportDate = value),
      ),
      _AlertsPage(repository: widget.repository),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('${user.name} | ${user.email}', style: const TextStyle(fontSize: 12, color: Color(0xFF5B6B7F))),
          ],
        ),
        actions: [
          TextButton(onPressed: widget.repository.logout, child: const Text('Logout')),
          const SizedBox(width: 12),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          if (compact) {
            return Column(
              children: [
                Expanded(child: pages[currentIndex]),
                NavigationBar(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (value) => setState(() => currentIndex = value),
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
                    NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
                    NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Customers'),
                    NavigationDestination(icon: Icon(Icons.design_services_outlined), label: 'Services'),
                    NavigationDestination(icon: Icon(Icons.date_range_outlined), label: 'Reports'),
                    NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              NavigationRail(
                selectedIndex: currentIndex,
                onDestinationSelected: (value) => setState(() => currentIndex = value),
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('Overview')),
                  NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), label: Text('Orders')),
                  NavigationRailDestination(icon: Icon(Icons.groups_outlined), label: Text('Customers')),
                  NavigationRailDestination(icon: Icon(Icons.design_services_outlined), label: Text('Services')),
                  NavigationRailDestination(icon: Icon(Icons.date_range_outlined), label: Text('Reports')),
                  NavigationRailDestination(icon: Icon(Icons.notifications_outlined), label: Text('Alerts')),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: pages[currentIndex]),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage({required this.repository});
  final AppRepository repository;

  @override
  Widget build(BuildContext context) {
    final stats = repository.computeStats();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const InfoHeroCard(
          kicker: 'Operations Center',
          title: 'Track every order and payment in one place.',
          body: 'Monitor order movement, customer growth, payment split, and permanent daily records.',
          pills: [
            StatPill(label: 'Data Retention', value: 'Permanent'),
            StatPill(label: 'Admin Routes', value: 'Restricted'),
            StatPill(label: 'Passwords', value: 'Hashed'),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            StatsCard(label: 'Total Orders', value: '${stats.totalOrders}', foot: 'All customer orders stored permanently'),
            StatsCard(label: 'Pending Orders', value: '${stats.pendingOrders}', foot: 'Pending and accepted combined'),
            StatsCard(label: 'Completed Orders', value: '${stats.completedOrders}', foot: 'Finished orders with payment captured'),
            StatsCard(label: 'Cancelled Orders', value: '${stats.cancelledOrders}', foot: 'Orders cancelled by the admin'),
            StatsCard(label: 'Online Payments', value: formatCurrency(stats.onlineTotal), foot: 'Completed orders paid online'),
            StatsCard(label: 'Offline Payments', value: formatCurrency(stats.offlineTotal), foot: 'Completed orders paid offline'),
            StatsCard(label: 'Total Revenue', value: formatCurrency(stats.totalRevenue), foot: 'Online plus offline completed revenue'),
            StatsCard(label: 'Total Customers', value: '${stats.totalCustomers}', foot: 'Registered customer accounts'),
          ],
        ),
      ],
    );
  }
}

class _OrdersPage extends StatelessWidget {
  const _OrdersPage({required this.repository, required this.filter, required this.onFilterChanged});

  final AppRepository repository;
  final OrderStatus? filter;
  final ValueChanged<OrderStatus?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final orders = repository.allOrders().where((order) => filter == null || order.status == filter).toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('All Orders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Accept, complete, cancel, or permanently remove customer requests.'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilterChip(label: const Text('All'), selected: filter == null, onSelected: (_) => onFilterChanged(null)),
                    ...OrderStatus.values.map(
                      (status) => FilterChip(
                        label: Text(orderStatusLabel(status)),
                        selected: filter == status,
                        onSelected: (_) => onFilterChanged(status),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (orders.isEmpty)
                  const EmptyPlaceholder(message: 'No orders match this filter.')
                else
                  ...orders.map((order) => _AdminOrderCard(repository: repository, order: order)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({required this.repository, required this.order});

  final AppRepository repository;
  final PrintOrder order;

  @override
  Widget build(BuildContext context) {
    final customer = repository.userById(order.userId);
    final service = repository.serviceById(order.serviceId);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.id, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${customer?.name ?? 'Unknown customer'} - ${customer?.phone ?? '-'}'),
                    Text(service?.name ?? 'Removed service', style: const TextStyle(color: Color(0xFF5B6B7F))),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [statusBadgeWidget(order.status), paymentBadgeWidget(order.paymentType)],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Quantity: ${order.quantity} - ${order.options.printMode} - ${order.options.paperSize}'),
            Text('Amount: ${formatCurrency(order.amount)}'),
            Text('File: ${order.fileName.isEmpty ? 'Not provided' : order.fileName}'),
            Text('Date: ${formatDateTime(order.createdAt)}'),
            if (order.options.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: ${order.options.notes}'),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton(
                  onPressed: order.status == OrderStatus.pending
                      ? () async {
                          await repository.acceptOrder(order.id);
                          if (context.mounted) showAppSnackBar(context, 'Order accepted.');
                        }
                      : null,
                  child: const Text('Accept'),
                ),
                FilledButton.tonal(
                  onPressed: order.status == OrderStatus.accepted ? () => _showCompleteDialog(context, repository, order) : null,
                  child: const Text('Complete'),
                ),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFEDEC)),
                  onPressed: (order.status == OrderStatus.completed || order.status == OrderStatus.cancelled)
                      ? null
                      : () async {
                          await repository.cancelOrder(order.id);
                          if (context.mounted) showAppSnackBar(context, 'Order cancelled.');
                        },
                  child: const Text('Cancel'),
                ),
                OutlinedButton(
                  onPressed: () => _confirmDeleteOrder(context, repository, order),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showCompleteDialog(BuildContext context, AppRepository repository, PrintOrder order) async {
  PaymentType paymentType = PaymentType.online;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Complete Order'),
      content: StatefulBuilder(
        builder: (context, setState) => DropdownButtonFormField<PaymentType>(
          value: paymentType,
          items: const [
            DropdownMenuItem(value: PaymentType.online, child: Text('ONLINE')),
            DropdownMenuItem(value: PaymentType.offline, child: Text('OFFLINE')),
          ],
          onChanged: (value) => setState(() => paymentType = value ?? PaymentType.online),
          decoration: const InputDecoration(labelText: 'Payment Type'),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            await repository.completeOrder(order.id, paymentType);
            if (!context.mounted) return;
            Navigator.pop(context);
            showAppSnackBar(context, 'Order completed.');
          },
          child: const Text('Complete Order'),
        ),
      ],
    ),
  );
}

Future<void> _confirmDeleteOrder(BuildContext context, AppRepository repository, PrintOrder order) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Order'),
      content: Text('Delete order ${order.id} permanently? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ),
  );

  if (confirmed == true) {
    await repository.deleteOrder(order.id);
    if (context.mounted) showAppSnackBar(context, 'Order removed permanently.');
  }
}

class _CustomersPage extends StatelessWidget {
  const _CustomersPage({required this.repository});

  final AppRepository repository;

  @override
  Widget build(BuildContext context) {
    final customers = repository.customers;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('All customer accounts and their order totals.'),
                const SizedBox(height: 20),
                if (customers.isEmpty)
                  const EmptyPlaceholder(message: 'No customers registered yet.')
                else
                  ...customers.map(
                    (customer) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${customer.phone}\n${customer.email}'),
                      isThreeLine: true,
                      trailing: Wrap(
                        direction: Axis.vertical,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 6,
                        children: [
                          statusChipText('Orders: ${repository.totalOrdersForCustomer(customer.id)}'),
                          statusChipText('Completed: ${repository.completedOrdersForCustomer(customer.id)}'),
                          FilledButton.tonal(
                            onPressed: () => _confirmDeleteCustomer(context, repository, customer),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _confirmDeleteCustomer(BuildContext context, AppRepository repository, AppUser customer) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Customer'),
      content: Text('Delete ${customer.name} permanently? Their orders and notifications will also be removed.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ),
  );

  if (confirmed == true) {
    await repository.deleteCustomer(customer.id);
    if (context.mounted) showAppSnackBar(context, '${customer.name} removed permanently.');
  }
}

class _ServicesPage extends StatelessWidget {
  const _ServicesPage({required this.repository, required this.editingServiceId, required this.onEdit, required this.onReset, required this.serviceNameController, required this.serviceDescriptionController, required this.servicePriceController, required this.serviceUnitController});

  final AppRepository repository;
  final String? editingServiceId;
  final ValueChanged<PrintService> onEdit;
  final VoidCallback onReset;
  final TextEditingController serviceNameController;
  final TextEditingController serviceDescriptionController;
  final TextEditingController servicePriceController;
  final TextEditingController serviceUnitController;

  @override
  Widget build(BuildContext context) {
    final services = repository.services;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ResponsiveSection(
          left: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(editingServiceId == null ? 'Add Service' : 'Update Service', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Create or update available print services and pricing.'),
                  const SizedBox(height: 18),
                  TextField(controller: serviceNameController, decoration: const InputDecoration(labelText: 'Service Name')),
                  const SizedBox(height: 14),
                  TextField(controller: serviceDescriptionController, maxLines: 4, decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: servicePriceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price'))),
                      const SizedBox(width: 14),
                      Expanded(child: TextField(controller: serviceUnitController, decoration: const InputDecoration(labelText: 'Unit'))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton(
                        onPressed: () async {
                          final price = double.tryParse(servicePriceController.text.trim());
                          if (serviceNameController.text.trim().isEmpty || serviceDescriptionController.text.trim().isEmpty || price == null || price <= 0) {
                            showAppSnackBar(context, 'Service name, description, and valid price are required.', isError: true);
                            return;
                          }
                          final wasEditing = editingServiceId != null;
                          await repository.saveService(serviceId: editingServiceId, name: serviceNameController.text, description: serviceDescriptionController.text, price: price, unit: serviceUnitController.text);
                          onReset();
                          if (context.mounted) showAppSnackBar(context, wasEditing ? 'Service updated.' : 'Service added.');
                        },
                        child: Text(editingServiceId == null ? 'Add Service' : 'Update Service'),
                      ),
                      if (editingServiceId != null) OutlinedButton(onPressed: onReset, child: const Text('Cancel Edit')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          right: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Services', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Existing services can be edited or deleted.'),
                  const SizedBox(height: 18),
                  if (services.isEmpty)
                    const EmptyPlaceholder(message: 'No services available.')
                  else
                    ...services.map(
                      (service) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: const Color(0xFFFAFCFD),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(service.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
                                  Text(formatCurrency(service.price), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F766E))),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(service.description),
                              const SizedBox(height: 6),
                              Text('Unit: ${service.unit}', style: const TextStyle(color: Color(0xFF5B6B7F))),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                children: [
                                  OutlinedButton(onPressed: () => onEdit(service), child: const Text('Edit')),
                                  FilledButton.tonal(
                                    onPressed: () async {
                                      await repository.deleteService(service.id);
                                      if (context.mounted) showAppSnackBar(context, 'Service deleted.');
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportsPage extends StatelessWidget {
  const _ReportsPage({required this.repository, required this.reportDate, required this.onDateChanged});

  final AppRepository repository;
  final DateTime reportDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final stats = repository.computeStats(forDate: reportDate);
    final orders = repository.allOrders().where((order) => isSameDay(order.createdAt, reportDate)).toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ResponsiveSection(
          left: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date-wise Report', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Filter permanent data by date without deleting any records.'),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(context: context, initialDate: reportDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                      if (picked != null) onDateChanged(picked);
                    },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(formatDate(reportDate)),
                  ),
                ],
              ),
            ),
          ),
          right: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Summary for ${formatDate(reportDate)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      StatPill(label: 'Total Orders', value: '${stats.totalOrders}'),
                      StatPill(label: 'Completed', value: '${stats.completedOrders}'),
                      StatPill(label: 'Pending', value: '${stats.pendingOrders}'),
                      StatPill(label: 'Cancelled', value: '${stats.cancelledOrders}'),
                      StatPill(label: 'Online Total', value: formatCurrency(stats.onlineTotal)),
                      StatPill(label: 'Offline Total', value: formatCurrency(stats.offlineTotal)),
                      StatPill(label: 'Revenue', value: formatCurrency(stats.totalRevenue)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Orders On Selected Date', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),
                if (orders.isEmpty)
                  const EmptyPlaceholder(message: 'No orders found for the selected date.')
                else
                  ...orders.map((order) {
                    final customer = repository.userById(order.userId);
                    final service = repository.serviceById(order.serviceId);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      title: Text('${order.id} - ${customer?.name ?? 'Unknown'}'),
                      subtitle: Text('${service?.name ?? 'Removed service'} - ${formatDateTime(order.createdAt)}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          statusBadgeWidget(order.status),
                          const SizedBox(height: 6),
                          Text(formatCurrency(order.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertsPage extends StatelessWidget {
  const _AlertsPage({required this.repository});
  final AppRepository repository;

  @override
  Widget build(BuildContext context) {
    final notifications = repository.notificationsForCurrentUser();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                          SizedBox(height: 8),
                          Text('New order alerts and order management events.'),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await repository.markNotificationsRead();
                        if (context.mounted) showAppSnackBar(context, 'Notifications marked as read.');
                      },
                      child: const Text('Mark as read'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (notifications.isEmpty)
                  const EmptyPlaceholder(message: 'No notifications yet.')
                else
                  ...notifications.map(
                    (note) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(note.message, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(formatDateTime(note.timestamp)),
                      trailing: StatusBadge(
                        label: noticeStatusLabel(note.status),
                        color: note.status == NoticeStatus.unread ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
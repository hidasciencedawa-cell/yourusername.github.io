import 'package:flutter/material.dart';

import '../models/app_models.dart';

void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? const Color(0xFFB42318) : const Color(0xFF0F766E),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class ResponsiveSection extends StatelessWidget {
  const ResponsiveSection({super.key, required this.left, required this.right});
  final Widget left;
  final Widget right;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(children: [left, const SizedBox(height: 20), right]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 20), Expanded(child: right)]);
      },
    );
  }
}

class InfoHeroCard extends StatelessWidget {
  const InfoHeroCard({super.key, required this.kicker, required this.title, required this.body, required this.pills});
  final String kicker;
  final String title;
  final String body;
  final List<Widget> pills;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(kicker.toUpperCase(), style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 32, height: 1.1, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(body, style: const TextStyle(fontSize: 16, color: Color(0xFF5B6B7F), height: 1.5)),
          const SizedBox(height: 18),
          Wrap(spacing: 10, runSpacing: 10, children: pills),
        ]),
      ),
    );
  }
}

class AuthPoint extends StatelessWidget {
  const AuthPoint({super.key, required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white.withOpacity(0.12), border: Border.all(color: Colors.white.withOpacity(0.20))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 6),
        Text(body, style: const TextStyle(color: Colors.white, height: 1.45)),
      ]),
    );
  }
}

class StatsCard extends StatelessWidget {
  const StatsCard({super.key, required this.label, required this.value, required this.foot});
  final String label;
  final String value;
  final String foot;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 12, color: Color(0xFF5B6B7F), fontWeight: FontWeight.w800, letterSpacing: 1.1)),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(foot, style: const TextStyle(color: Color(0xFF5B6B7F))),
          ]),
        ),
      ),
    );
  }
}

class StatPill extends StatelessWidget {
  const StatPill({super.key, required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: color.withOpacity(0.14)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class EmptyPlaceholder extends StatelessWidget {
  const EmptyPlaceholder({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color(0xFFFAFCFD), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Text(message, style: const TextStyle(color: Color(0xFF5B6B7F))),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.serviceName, required this.customerName});
  final PrintOrder order;
  final String serviceName;
  final String customerName;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.id, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(serviceName),
              Text(customerName, style: const TextStyle(color: Color(0xFF5B6B7F))),
            ]),
            Wrap(spacing: 8, children: [statusBadgeWidget(order.status), paymentBadgeWidget(order.paymentType)]),
          ]),
          const SizedBox(height: 12),
          Text('Quantity: ${order.quantity} • ${order.options.printMode} • ${order.options.paperSize}'),
          Text('Amount: ${formatCurrency(order.amount)}'),
          Text('File: ${order.fileName.isEmpty ? 'Not provided' : order.fileName}'),
          Text('Date: ${formatDateTime(order.createdAt)}'),
          if (order.options.notes.isNotEmpty) ...[const SizedBox(height: 8), Text('Notes: ${order.options.notes}')],
        ]),
      ),
    );
  }
}

Widget statusBadgeWidget(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return const StatusBadge(label: 'PENDING', color: Color(0xFFF59E0B));
    case OrderStatus.accepted:
      return const StatusBadge(label: 'ACCEPTED', color: Color(0xFF0EA5E9));
    case OrderStatus.completed:
      return const StatusBadge(label: 'COMPLETED', color: Color(0xFF15803D));
    case OrderStatus.cancelled:
      return const StatusBadge(label: 'CANCELLED', color: Color(0xFFB42318));
  }
}

Widget paymentBadgeWidget(PaymentType paymentType) {
  switch (paymentType) {
    case PaymentType.notSelected:
      return const StatusBadge(label: 'NOT_SELECTED', color: Color(0xFF64748B));
    case PaymentType.online:
      return const StatusBadge(label: 'ONLINE', color: Color(0xFF0284C7));
    case PaymentType.offline:
      return const StatusBadge(label: 'OFFLINE', color: Color(0xFF7C3AED));
  }
}

Widget statusChipText(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
  );
}
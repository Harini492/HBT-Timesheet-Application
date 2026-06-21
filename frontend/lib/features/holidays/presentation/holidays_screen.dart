import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/errors/exceptions.dart';
import '../../auth/domain/auth_notifier.dart';
import '../../dashboard/presentation/top_bar.dart';
import '../data/holiday_model.dart';

class HolidaysScreen extends ConsumerStatefulWidget {
  const HolidaysScreen({super.key});

  @override
  ConsumerState<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends ConsumerState<HolidaysScreen> {
  List<Holiday>? _holidays;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final holidays = await ref.read(holidaysRepositoryProvider).list();
      setState(() => _holidays = holidays);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to load holidays.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(Holiday holiday) async {
    try {
      await ref.read(holidaysRepositoryProvider).delete(holiday.id);
      _load();
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _showAddDialog() {
    final dateController = TextEditingController();
    final nameController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Holiday'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(selectedDate == null
                    ? 'Pick a date'
                    : DateFormat('yyyy-MM-dd').format(selectedDate!)),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedDate = picked;
                      dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                    });
                  }
                },
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Holiday Name'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedDate == null || nameController.text.trim().isEmpty) return;
                try {
                  await ref.read(holidaysRepositoryProvider).create(
                        date: dateController.text,
                        name: nameController.text.trim(),
                      );
                  if (mounted) {
                    Navigator.of(context).pop();
                    _load();
                  }
                } on AppException catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authNotifierProvider).user?.isAdmin ?? false;

    final body = Column(
      children: [
        PageHeader(title: 'Global Holidays'),
        Expanded(
          child: Builder(builder: (context) {
            if (_isLoading) return const LoadingView();
            if (_error != null) return ErrorView(message: _error!, onRetry: _load);
            final holidays = _holidays ?? [];
            if (holidays.isEmpty) {
              return const EmptyView(message: 'No holidays configured yet.', icon: Icons.event_busy);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: holidays.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final h = holidays[i];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.rowHighlight,
                    child: Icon(Icons.event, color: AppColors.navyPrimary, size: 18),
                  ),
                  title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(DateFormat('EEEE, MMMM d, yyyy').format(DateTime.parse(h.date))),
                  trailing: isAdmin
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: () => _delete(h),
                        )
                      : null,
                );
              },
            );
          }),
        ),
      ],
    );

    if (!isAdmin) return body;

    return Stack(
      children: [
        body,
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            backgroundColor: AppColors.navyPrimary,
            onPressed: _showAddDialog,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

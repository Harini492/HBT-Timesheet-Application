import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/empty_view.dart';
import '../../dashboard/presentation/top_bar.dart';
import '../domain/report_provider.dart';
import '../data/report_models.dart';
import 'report_excel_exporter.dart';

/// Monthly report screen — matches screenshot 2: month navigator, then a
/// calendar-style grid where every day of the month is a column, job rows
/// on the left show a total plus a light-blue bar/number in each day cell
/// that has logged hours.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportNotifierProvider);
    final report = state.report;

    return Column(
      children: [
        PageHeader(title: 'Timesheet Report'),
        Expanded(
          child: Builder(builder: (context) {
            if (state.status == ReportLoadStatus.loading && report == null) {
              return const LoadingView(message: 'Loading report...');
            }
            if (state.status == ReportLoadStatus.error) {
              return ErrorView(
                message: state.errorMessage ?? 'Failed to load report',
                onRetry: () => ref.read(reportNotifierProvider.notifier).load(),
              );
            }
            if (report == null) return const SizedBox.shrink();

            final monthName = DateFormat('MMM').format(DateTime(report.year, report.month));
            final daysInMonth = DateTime(report.year, report.month + 1, 0).day;
            final dayDates = List<DateTime>.generate(
              daysInMonth,
              (i) => DateTime(report.year, report.month, i + 1),
            );

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left, color: AppColors.navyPrimary),
                                onPressed: () => ref.read(reportNotifierProvider.notifier).previousMonth(),
                              ),
                              Text(
                                monthName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColors.navyPrimary,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right, color: AppColors.navyPrimary),
                                onPressed: () => ref.read(reportNotifierProvider.notifier).nextMonth(),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${report.year}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.navyPrimary),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                ':: ${report.totalHours.toStringAsFixed(report.totalHours == report.totalHours.roundToDouble() ? 0 : 1)} hours',
                                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: report.jobs.isEmpty
                            ? null
                            : () => ReportExcelExporter.exportMonthlyReport(report),
                        icon: const Icon(Icons.file_download_outlined, size: 18),
                        label: const Text('Export to Excel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navyPrimary,
                          side: const BorderSide(color: AppColors.navyPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (report.jobs.isEmpty)
                    const Expanded(
                      child: EmptyView(
                        message: 'No hours logged this month yet.',
                        icon: Icons.bar_chart_outlined,
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 160 + (52.0 * daysInMonth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const SizedBox(width: 160),
                                  ...dayDates.map((d) => SizedBox(
                                        width: 52,
                                        child: Column(
                                          children: [
                                            Text('${d.day}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                            Text(DateFormat('EEE').format(d), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...report.jobs.map((job) => _JobReportRow(job: job, dayDates: dayDates)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _JobReportRow extends StatelessWidget {
  final MonthlyReportJobRow job;
  final List<DateTime> dayDates;

  const _JobReportRow({required this.job, required this.dayDates});

  @override
  Widget build(BuildContext context) {
    final maxHours = job.dailyHours.values.isEmpty
        ? 1.0
        : job.dailyHours.values.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              job.jobDescription,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navyPrimary, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              job.total == job.total.roundToDouble() ? job.total.toInt().toString() : job.total.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyPrimary, fontSize: 13),
            ),
          ),
          ...dayDates.map((d) {
            final dateKey = DateFormat('yyyy-MM-dd').format(d);
            final hours = job.dailyHours[dateKey] ?? 0;
            final widthFraction = maxHours > 0 ? (hours / maxHours).clamp(0.0, 1.0) : 0.0;
            return SizedBox(
              width: 52,
              height: 26,
              child: hours > 0
                  ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: AppColors.rowHighlight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: widthFraction.clamp(0.15, 1.0),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCFE3F7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            hours == hours.roundToDouble() ? hours.toInt().toString() : hours.toString(),
                            style: const TextStyle(fontSize: 11, color: AppColors.navyPrimary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    )
                  : null,
            );
          }),
        ],
      ),
    );
  }
}

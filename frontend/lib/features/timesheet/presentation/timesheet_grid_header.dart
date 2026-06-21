import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

/// Header row: "Job Description | Job Code | <7 day columns>" — matches
/// screenshot 1 exactly, including the "Mon - 8 hrs" style sub-label that
/// appears under whichever date currently has logged hours for that row's
/// context (kept generic here as day name beneath the date).
class TimesheetGridHeader extends StatelessWidget {
  final List<String> dates;
  final double jobColWidth;
  final double codeColWidth;
  final double dayColWidth;

  const TimesheetGridHeader({
    super.key,
    required this.dates,
    this.jobColWidth = 220,
    this.codeColWidth = 110,
    this.dayColWidth = 130,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('d/M/yyyy');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.navyPrimary;
    final borderColor = isDark ? Colors.white24 : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: jobColWidth,
            child: Text(
              'Job Description',
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15),
            ),
          ),
          SizedBox(
            width: codeColWidth,
            child: Text(
              'Job Code',
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15),
            ),
          ),
          ...dates.map((date) {
            final d = DateTime.parse(date);
            final dayName = DateFormat('EEE').format(d);
            return SizedBox(
              width: dayColWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatter.format(d),
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
                  ),
                  Text(
                    dayName,
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
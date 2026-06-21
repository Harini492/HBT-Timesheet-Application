import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/timesheet_models.dart';

/// One job row: dropdown-styled job name (kept as text per spec, since the
/// job itself can't be changed once added — only removed), job code, and
/// editable hour fields per day. Matches screenshot 1's alternating
/// light-blue row highlight and bordered hour boxes.
class TimesheetRowWidget extends StatelessWidget {
  final TimesheetRow row;
  final List<String> dates;
  final bool isAlternate;
  final void Function(String date, double hours) onHourChanged;
  final VoidCallback onRemove;
  final double jobColWidth;
  final double codeColWidth;
  final double dayColWidth;

  const TimesheetRowWidget({
    super.key,
    required this.row,
    required this.dates,
    required this.onHourChanged,
    required this.onRemove,
    this.isAlternate = false,
    this.jobColWidth = 220,
    this.codeColWidth = 110,
    this.dayColWidth = 130,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.navyPrimary;
    final borderColor = isDark ? Colors.white24 : AppColors.lightBorder;

    return Container(
      color: isAlternate
          ? (isDark ? Colors.white.withOpacity(0.04) : AppColors.rowHighlight)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: jobColWidth,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      row.jobDescription,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: isDark ? Colors.white70 : Colors.grey),
                  tooltip: 'Remove row',
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
          SizedBox(
            width: codeColWidth,
            child: Text(
              row.jobCode,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
          ),
          ...dates.map((date) {
            return SizedBox(
              width: dayColWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _HourField(
                  initialValue: row.hoursByDate[date] ?? 0,
                  onChanged: (value) => onHourChanged(date, value),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HourField extends StatefulWidget {
  final double initialValue;
  final void Function(double) onChanged;

  const _HourField({required this.initialValue, required this.onChanged});

  @override
  State<_HourField> createState() => _HourFieldState();
}

class _HourFieldState extends State<_HourField> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue == 0 ? '' : _formatHours(widget.initialValue),
    );
  }

  String _formatHours(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String text) {
    if (text.trim().isEmpty) {
      setState(() => _error = null);
      widget.onChanged(0);
      return;
    }
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0 || parsed > 24) {
      setState(() => _error = 'Max 24');
      return;
    }
    setState(() => _error = null);
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.navyPrimary;
    final borderColor = _error != null
        ? AppColors.error
        : (isDark ? Colors.white38 : AppColors.lightBorder);

    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      onChanged: _handleChanged,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor),
        ),
        errorText: _error,
        errorStyle: const TextStyle(fontSize: 10, height: 0.6),
      ),
    );
  }
}
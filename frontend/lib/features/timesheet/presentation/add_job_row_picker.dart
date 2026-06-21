import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/timesheet_models.dart';

/// "+ Add Job" control: a dropdown of jobs assigned to the employee that
/// aren't already shown as a row, matching the spec's "employee picks from
/// assigned jobs, adds rows" requirement.
class AddJobRowPicker extends StatelessWidget {
  final List<AssignableJob> availableJobs;
  final void Function(AssignableJob job) onAdd;

  const AddJobRowPicker({super.key, required this.availableJobs, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    if (availableJobs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'All assigned jobs are already on this timesheet.',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: PopupMenuButton<AssignableJob>(
        onSelected: onAdd,
        itemBuilder: (context) => availableJobs
            .map((job) => PopupMenuItem(
                  value: job,
                  child: Text('${job.jobDescription} (${job.jobCode})'),
                ))
            .toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.accentBlue),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 18, color: AppColors.accentBlue),
              SizedBox(width: 6),
              Text('Add Job', style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

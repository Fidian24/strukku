import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';

/// Bottom sheet pemilih bulan (hanya bulan yang memiliki data).
Future<DateTime?> showMonthPicker(
  BuildContext context, {
  required List<DateTime> months,
  required DateTime selected,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Pilih bulan',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy)),
          ),
          if (months.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belum ada data bulan manapun.',
                  style: TextStyle(color: AppColors.textGrey)),
            ),
          for (final m in months)
            ListTile(
              title: Text(Fmt.monthYear(m)),
              trailing: (m.year == selected.year && m.month == selected.month)
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, m),
            ),
        ],
      ),
    ),
  );
}

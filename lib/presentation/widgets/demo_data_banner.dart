import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/app_provider.dart';

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, provider, __) {
        if (!provider.isUsingDemoData) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.moderate.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.moderate.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: AppColors.moderate, size: 14),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Offline · Showing demo data. Configure INCOIS API key in Settings.',
                  style: TextStyle(color: AppColors.moderate, fontSize: 11),
                ),
              ),
              GestureDetector(
                onTap: provider.refreshAll,
                child: const Icon(Icons.refresh_rounded,
                    color: AppColors.moderate, size: 16),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'app_design_system.dart';

class AppStepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;

  const AppStepper({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    required this.stepTitles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              final isCompleted = index < currentStep;
              final isActive = index == currentStep;

              return Expanded(
                child: Row(
                  children: [
                    // Step Circle Indicator with scaling & implicit animations
                    AnimatedContainer(
                      duration: AppAnimation.fast,
                      curve: Curves.easeInOut,
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.secondary
                            : isActive
                                ? AppColors.primary
                                : (isDark ? Colors.grey[800] : Colors.grey[300]),
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: AppAnimation.fast,
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                  key: ValueKey('completed'),
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: (isActive || isCompleted)
                                        ? Colors.white
                                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  key: ValueKey('number_$index'),
                                ),
                        ),
                      ),
                    ),
                    // Line Connector
                    if (index < totalSteps - 1)
                      Expanded(
                        child: AnimatedContainer(
                          duration: AppAnimation.fast,
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.secondary
                                : (isDark ? Colors.grey[800] : Colors.grey[300]),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Titles for steps
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final isActive = index == currentStep;
              final isCompleted = index < currentStep;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Text(
                    stepTitles[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: (isActive || isCompleted) ? FontWeight.bold : FontWeight.normal,
                      color: isActive
                          ? AppColors.primary
                          : isCompleted
                              ? AppColors.secondary
                              : (isDark ? Colors.grey[500] : Colors.grey[600]),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

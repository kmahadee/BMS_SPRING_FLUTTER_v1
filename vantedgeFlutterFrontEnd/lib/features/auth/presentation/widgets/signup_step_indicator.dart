import 'package:flutter/material.dart';

class SignupStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const SignupStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    this.stepLabels = const ['Personal', 'Contact', 'Credentials'],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps * 2 - 1, (index) {
              if (index.isEven) {
                final stepIndex = index ~/ 2;
                return _buildStepCircle(stepIndex);
              } else {
                final stepIndex = index ~/ 2;
                return _buildStepLine(stepIndex);
              }
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              totalSteps,
              (index) => Expanded(
                child: Text(
                  stepLabels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: currentStep == index
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: currentStep >= index
                        ? const Color(0xFF1A237E)
                        : Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int stepIndex) {
    final isCompleted = stepIndex < currentStep;
    final isActive = stepIndex == currentStep;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isActive
            ? const Color(0xFF1A237E)
            : Colors.grey[300],
        border: Border.all(
          color: isActive ? const Color(0xFF1A237E) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text(
                '${stepIndex + 1}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : Colors.grey[600],
                ),
              ),
      ),
    );
  }

  Widget _buildStepLine(int stepIndex) {
    final isCompleted = stepIndex < currentStep;

    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? const Color(0xFF1A237E) : Colors.grey[300],
      ),
    );
  }
}
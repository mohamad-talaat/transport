import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditModeButtons extends StatelessWidget {
  final RxString currentStep;
  final int additionalStopsCount;
  final ValueChanged<String> onSetMode;

  const EditModeButtons({
    super.key,
    required this.currentStep,
    required this.additionalStopsCount,
    required this.onSetMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildModeButton(
            isActive: currentStep.value == 'destination',
            icon: Icons.flag,
            label: 'تعديل الوجهة',
            onTap: () => onSetMode('destination'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModeButton(
            isActive: currentStep.value == 'additional_stop',
            icon: Icons.add_location_alt,
            label: 'إضافة توقف ($additionalStopsCount/2)',
            onTap: () {
              if (additionalStopsCount >= 2) {
                Get.snackbar('تنبيه', 'لا يمكن إضافة أكثر من نقطتي توقف',
                    backgroundColor: Colors.orange, colorText: Colors.white);
                return;
              }
              onSetMode('additional_stop');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton(
      {required bool isActive,
      required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)])
              : null,
          color: isActive ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.grey.shade600, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? Colors.white : Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
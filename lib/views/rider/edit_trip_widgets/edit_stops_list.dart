import 'package:flutter/material.dart';
import 'package:get/get.dart';
 import 'package:transport_app/models/trip_model.dart';
 
class EditStopsList extends StatelessWidget {
  final RxList<AdditionalStop> additionalStops;
  final RxString currentStep;
   final Function(int) onEdit;
  final Function(int) onDelete;

  const EditStopsList({
    super.key,
    required this.additionalStops,
    required this.currentStep,
     required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (additionalStops.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'لا توجد نقاط توقف. اضغط "إضافة توقف" لإضافة نقطة جديدة',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color.fromARGB(255, 2, 50, 90),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نقاط التوقف (${additionalStops.length}/2)',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...additionalStops.asMap().entries.map((entry) {
            final index = entry.key;
            final stop = entry.value;
            final isEditing = currentStep.value == 'edit_stop_$index';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isEditing ? Colors.green.shade100 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isEditing ? const Color(0xFF2E7D32) : Colors.green.shade200,
                  width: isEditing ? 2 : 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 2}', // Start numbering from 2
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  stop.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isEditing ? Icons.check : Icons.edit,
                        color: isEditing ? Colors.green : const Color(0xFF2E7D32),
                        size: 20,
                      ),
                      onPressed: () => isEditing ? onEdit(-1) : onEdit(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => onDelete(index),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    });
  }
} 

   
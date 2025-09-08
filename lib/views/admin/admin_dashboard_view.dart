// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../services/app_settings_service.dart';
// import '../../services/notification_service.dart';
// import '../../models/app_settings_model.dart';

// class AdminDashboardView extends StatefulWidget {
//   const AdminDashboardView({super.key});

//   @override
//   State<AdminDashboardView> createState() => _AdminDashboardViewState();
// }

// class _AdminDashboardViewState extends State<AdminDashboardView> {
//   final AppSettingsService _settingsService = AppSettingsService.to;
//   final NotificationService _notificationService = NotificationService.to;

//   // Controllers for form fields
//   final TextEditingController _baseFareController = TextEditingController();
//   final TextEditingController _perKmRateController = TextEditingController();
//   final TextEditingController _minimumFareController = TextEditingController();
//   final TextEditingController _maximumFareController = TextEditingController();

//   // Notification controllers
//   final TextEditingController _notificationTitleController =
//       TextEditingController();
//   final TextEditingController _notificationMessageController =
//       TextEditingController();
//   final TextEditingController _autoDeleteHoursController =
//       TextEditingController();

//   // Selected governorates
//   final RxList<String> _selectedSupported = <String>[].obs;
//   final RxList<String> _selectedUnsupported = <String>[].obs;

//   // Governorate rate controllers
//   final Map<String, TextEditingController> _governorateRateControllers = {};

//   // Notification settings
//   final RxBool _isSendingNotification = false.obs;
//   final RxBool _sendToAllUsers = true.obs;
//   final RxList<String> _selectedUserTypes = <String>[].obs;
//   final RxList<String> _selectedGovernorates = <String>[].obs;

//   @override
//   void initState() {
//     super.initState();
//     _initializeForm();
//     _initializeNotificationForm();
//   }

//   void _initializeForm() {
//     ever(_settingsService.currentSettings, (AppSettingsModel? settings) {
//       if (settings != null) {
//         _updateFormFields(settings);
//       }
//     });
//   }

//   void _initializeNotificationForm() {
//     _autoDeleteHoursController.text = '24'; // Default 24 hours
//     _selectedUserTypes.value = ['rider', 'driver']; // Default to all user types
//   }

//   void _updateFormFields(AppSettingsModel settings) {
//     _baseFareController.text = settings.baseFare.toString();
//     _perKmRateController.text = settings.perKmRate.toString();
//     _minimumFareController.text = settings.minimumFare.toString();
//     _maximumFareController.text = settings.maximumFare.toString();

//     _selectedSupported.value = List.from(settings.supportedGovernorates);
//     _selectedUnsupported.value = List.from(settings.unsupportedGovernorates);

//     // Update governorate rate controllers
//     for (String governorate in IraqiGovernorates.allGovernorates) {
//       if (!_governorateRateControllers.containsKey(governorate)) {
//         _governorateRateControllers[governorate] = TextEditingController();
//       }

//       double? rate = settings.governorateRates[governorate];
//       _governorateRateControllers[governorate]!.text = rate?.toString() ?? '';
//     }
//   }

//   @override
//   void dispose() {
//     _baseFareController.dispose();
//     _perKmRateController.dispose();
//     _minimumFareController.dispose();
//     _maximumFareController.dispose();

//     // Notification controllers
//     _notificationTitleController.dispose();
//     _notificationMessageController.dispose();
//     _autoDeleteHoursController.dispose();

//     for (var controller in _governorateRateControllers.values) {
//       controller.dispose();
//     }

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 4,
//       child: Scaffold(
//         backgroundColor: const Color.fromARGB(255, 243, 241, 233),
//         appBar: AppBar(
//           title: const Text(
//             'داشبورد الإدارة',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           backgroundColor: Colors.amber.shade300,
//           elevation: 0,
//           centerTitle: true,
//           iconTheme: const IconThemeData(color: Colors.black87),
//           bottom: const TabBar(
//             labelColor: Colors.black87,
//             unselectedLabelColor: Colors.black54,
//             indicatorColor: Colors.black87,
//             tabs: [
//               Tab(icon: Icon(Icons.settings), text: 'الإعدادات'),
//               Tab(icon: Icon(Icons.people), text: 'إدارة السائقين'),
//               Tab(icon: Icon(Icons.notifications), text: 'الإشعارات'),
//               Tab(icon: Icon(Icons.analytics), text: 'الإحصائيات'),
//             ],
//           ),
//         ),
//         body: Obx(() {
//           if (_settingsService.isLoading.value) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           }

//           return TabBarView(
//             children: [
//               _buildGeneralSettingsTab(),
//               _buildDriverManagementTab(),
//               _buildNotificationManagementTab(),
//               _buildSystemStatisticsTab(),
//             ],
//           );
//         }),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.admin_panel_settings,
//                   color: Colors.amber.shade700, size: 28),
//               const SizedBox(width: 12),
//               const Text(
//                 'إعدادات التطبيق',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'إدارة الأسعار والمحافظات المدعومة',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey.shade600,
//             ),
//           ),
//           if (_settingsService.currentSettings.value != null) ...[
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
//                 const SizedBox(width: 8),
//                 Text(
//                   'آخر تحديث: ${_formatDate(_settingsService.currentSettings.value!.lastUpdated)}',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey.shade500,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildPricingSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.attach_money, color: Colors.green.shade600, size: 24),
//               const SizedBox(width: 12),
//               const Text(
//                 'إعدادات الأسعار',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildTextField(
//                   controller: _baseFareController,
//                   label: 'السعر الأساسي (ج.م)',
//                   hint: '10.0',
//                   icon: Icons.start,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: _buildTextField(
//                   controller: _perKmRateController,
//                   label: 'السعر لكل كم (ج.م)',
//                   hint: '3.0',
//                   icon: Icons.straighten,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildTextField(
//                   controller: _minimumFareController,
//                   label: 'الحد الأدنى (ج.م)',
//                   hint: '5.0',
//                   icon: Icons.trending_down,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: _buildTextField(
//                   controller: _maximumFareController,
//                   label: 'الحد الأقصى (ج.م)',
//                   hint: '100.0',
//                   icon: Icons.trending_up,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton.icon(
//               onPressed:
//                   _settingsService.isUpdating.value ? null : _updatePricing,
//               icon: _settingsService.isUpdating.value
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     )
//                   : const Icon(Icons.save),
//               label: Text(_settingsService.isUpdating.value
//                   ? 'جاري الحفظ...'
//                   : 'حفظ الأسعار'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGovernoratesSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.location_city, color: Colors.blue.shade600, size: 24),
//               const SizedBox(width: 12),
//               const Text(
//                 'إدارة المحافظات',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildGovernorateList(
//                   title: 'المحافظات المدعومة',
//                   governorates: _selectedSupported,
//                   color: Colors.green,
//                   onAdd: _addSupportedGovernorate,
//                   onRemove: _removeSupportedGovernorate,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: _buildGovernorateList(
//                   title: 'المحافظات غير المدعومة',
//                   governorates: _selectedUnsupported,
//                   color: Colors.red,
//                   onAdd: _addUnsupportedGovernorate,
//                   onRemove: _removeUnsupportedGovernorate,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton.icon(
//               onPressed: _settingsService.isUpdating.value
//                   ? null
//                   : _updateGovernorates,
//               icon: _settingsService.isUpdating.value
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     )
//                   : const Icon(Icons.save),
//               label: Text(_settingsService.isUpdating.value
//                   ? 'جاري الحفظ...'
//                   : 'حفظ المحافظات'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGovernorateList({
//     required String title,
//     required RxList<String> governorates,
//     required Color color,
//     required Function(String) onAdd,
//     required Function(String) onRemove,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Obx(() => Column(
//                 children: governorates
//                     .map((governorate) => _buildGovernorateItem(
//                           governorate,
//                           color,
//                           () => onRemove(governorate),
//                         ))
//                     .toList(),
//               )),
//           const SizedBox(height: 12),
//           _buildGovernorateDropdown(
//             onSelect: onAdd,
//             excludeGovernorates: governorates,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGovernorateItem(
//       String governorate, Color color, VoidCallback onRemove) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.location_city, size: 16, color: color),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               governorate,
//               style: const TextStyle(fontSize: 14),
//             ),
//           ),
//           IconButton(
//             onPressed: onRemove,
//             icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
//             padding: EdgeInsets.zero,
//             constraints: const BoxConstraints(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGovernorateDropdown({
//     required Function(String) onSelect,
//     required List<String> excludeGovernorates,
//   }) {
//     List<String> availableGovernorates = IraqiGovernorates.allGovernorates
//         .where((g) => !excludeGovernorates.contains(g))
//         .toList();

//     if (availableGovernorates.isEmpty) {
//       return Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.grey.shade100,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Text(
//           'لا توجد محافظات متاحة',
//           style: TextStyle(
//             color: Colors.grey.shade600,
//             fontSize: 14,
//           ),
//         ),
//       );
//     }

//     return DropdownButtonFormField<String>(
//       decoration: InputDecoration(
//         labelText: 'إضافة محافظة',
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       ),
//       items: availableGovernorates.map((governorate) {
//         return DropdownMenuItem(
//           value: governorate,
//           child: Text(governorate),
//         );
//       }).toList(),
//       onChanged: (value) {
//         if (value != null) {
//           onSelect(value);
//         }
//       },
//     );
//   }

//   Widget _buildGovernorateRatesSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.local_offer, color: Colors.orange.shade600, size: 24),
//               const SizedBox(width: 12),
//               const Text(
//                 'أسعار خاصة للمحافظات',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'اترك الحقل فارغاً لاستخدام السعر الافتراضي',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade600,
//             ),
//           ),
//           const SizedBox(height: 20),
//           GridView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               childAspectRatio: 3,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//             ),
//             itemCount: IraqiGovernorates.allGovernorates.length,
//             itemBuilder: (context, index) {
//               String governorate = IraqiGovernorates.allGovernorates[index];
//               return _buildGovernorateRateField(governorate);
//             },
//           ),
//           const SizedBox(height: 20),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton.icon(
//               onPressed: _settingsService.isUpdating.value
//                   ? null
//                   : _updateGovernorateRates,
//               icon: _settingsService.isUpdating.value
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     )
//                   : const Icon(Icons.save),
//               label: Text(_settingsService.isUpdating.value
//                   ? 'جاري الحفظ...'
//                   : 'حفظ الأسعار الخاصة'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGovernorateRateField(String governorate) {
//     return _buildTextField(
//       controller: _governorateRateControllers[governorate]!,
//       label: governorate,
//       hint: 'السعر لكل كم',
//       icon: Icons.attach_money,
//       isSmall: true,
//     );
//   }

//   Widget _buildActionsSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.settings, color: Colors.purple.shade600, size: 24),
//               const SizedBox(width: 12),
//               const Text(
//                 'إجراءات إدارية',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: _settingsService.isUpdating.value
//                       ? null
//                       : _resetToDefaults,
//                   icon: const Icon(Icons.refresh),
//                   label: const Text('إعادة تعيين'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.purple,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: _settingsService.isUpdating.value
//                       ? null
//                       : _toggleActiveStatus,
//                   icon: Obx(() => Icon(
//                         _settingsService.currentSettings.value?.isActive == true
//                             ? Icons.pause
//                             : Icons.play_arrow,
//                       )),
//                   label: Obx(() => Text(
//                         _settingsService.currentSettings.value?.isActive == true
//                             ? 'إيقاف مؤقت'
//                             : 'تفعيل',
//                       )),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required IconData icon,
//     bool isSmall = false,
//   }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: TextInputType.number,
//       decoration: InputDecoration(
//         labelText: label,
//         hintText: hint,
//         prefixIcon: Icon(icon, size: isSmall ? 16 : 20),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//         contentPadding: EdgeInsets.symmetric(
//           horizontal: 12,
//           vertical: isSmall ? 8 : 12,
//         ),
//       ),
//     );
//   }

//   // Action methods
//   Future<void> _updatePricing() async {
//     try {
//       double? baseFare = double.tryParse(_baseFareController.text);
//       double? perKmRate = double.tryParse(_perKmRateController.text);
//       double? minimumFare = double.tryParse(_minimumFareController.text);
//       double? maximumFare = double.tryParse(_maximumFareController.text);

//       if (baseFare == null ||
//           perKmRate == null ||
//           minimumFare == null ||
//           maximumFare == null) {
//         Get.snackbar(
//           'خطأ',
//           'يرجى إدخال قيم صحيحة للأسعار',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//         );
//         return;
//       }

//       await _settingsService.updateSettings(
//         baseFare: baseFare,
//         perKmRate: perKmRate,
//         minimumFare: minimumFare,
//         maximumFare: maximumFare,
//         updatedBy: 'admin',
//       );
//     } catch (e) {
//       Get.snackbar(
//         'خطأ',
//         'تعذر تحديث الأسعار',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }

//   Future<void> _updateGovernorates() async {
//     try {
//       await _settingsService.updateSettings(
//         supportedGovernorates: _selectedSupported,
//         unsupportedGovernorates: _selectedUnsupported,
//         updatedBy: 'admin',
//       );
//     } catch (e) {
//       Get.snackbar(
//         'خطأ',
//         'تعذر تحديث المحافظات',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }

//   Future<void> _updateGovernorateRates() async {
//     try {
//       Map<String, double> rates = {};

//       for (String governorate in IraqiGovernorates.allGovernorates) {
//         String value = _governorateRateControllers[governorate]!.text.trim();
//         if (value.isNotEmpty) {
//           double? rate = double.tryParse(value);
//           if (rate != null && rate > 0) {
//             rates[governorate] = rate;
//           }
//         }
//       }

//       await _settingsService.updateSettings(
//         governorateRates: rates,
//         updatedBy: 'admin',
//       );
//     } catch (e) {
//       Get.snackbar(
//         'خطأ',
//         'تعذر تحديث الأسعار الخاصة',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }

//   Future<void> _resetToDefaults() async {
//     try {
//       bool confirmed = await Get.dialog<bool>(
//             AlertDialog(
//               title: const Text('تأكيد'),
//               content: const Text(
//                   'هل أنت متأكد من إعادة تعيين جميع الإعدادات إلى الافتراضية؟'),
//               actions: [
//                 TextButton(
//                   onPressed: () => Get.back(result: false),
//                   child: const Text('إلغاء'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => Get.back(result: true),
//                   child: const Text('تأكيد'),
//                 ),
//               ],
//             ),
//           ) ??
//           false;

//       if (confirmed) {
//         await _settingsService.resetToDefaults(updatedBy: 'admin');
//       }
//     } catch (e) {
//       Get.snackbar(
//         'خطأ',
//         'تعذر إعادة التعيين',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }

//   Future<void> _toggleActiveStatus() async {
//     try {
//       bool currentStatus =
//           _settingsService.currentSettings.value?.isActive ?? true;
//       await _settingsService.updateSettings(
//         isActive: !currentStatus,
//         updatedBy: 'admin',
//       );
//     } catch (e) {
//       Get.snackbar(
//         'خطأ',
//         'تعذر تغيير حالة التفعيل',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }

//   void _addSupportedGovernorate(String governorate) {
//     if (!_selectedSupported.contains(governorate)) {
//       _selectedSupported.add(governorate);
//       _selectedUnsupported.remove(governorate);
//     }
//   }

//   void _removeSupportedGovernorate(String governorate) {
//     _selectedSupported.remove(governorate);
//   }

//   void _addUnsupportedGovernorate(String governorate) {
//     if (!_selectedUnsupported.contains(governorate)) {
//       _selectedUnsupported.add(governorate);
//       _selectedSupported.remove(governorate);
//     }
//   }

//   void _removeUnsupportedGovernorate(String governorate) {
//     _selectedUnsupported.remove(governorate);
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
//   }

//   // Tab 1: General Settings
//   Widget _buildGeneralSettingsTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildHeader(),
//           const SizedBox(height: 24),
//           _buildPricingSection(),
//           const SizedBox(height: 24),
//           _buildGovernoratesSection(),
//           const SizedBox(height: 24),
//           _buildGovernorateRatesSection(),
//           const SizedBox(height: 24),
//           _buildActionsSection(),
//         ],
//       ),
//     );
//   }

//   // Tab 2: Driver Management
//   Widget _buildDriverManagementTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildDriverManagementHeader(),
//           const SizedBox(height: 20),
//           _buildDriverStatsCards(),
//           const SizedBox(height: 20),
//           _buildDriverManagementActions(),
//           const SizedBox(height: 20),
//           _buildRecentDriverApplications(),
//         ],
//       ),
//     );
//   }

//   // Tab 2: Notification Management
//   Widget _buildNotificationManagementTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildNotificationFormCard(),
//           const SizedBox(height: 20),
//           _buildNotificationTargetingCard(),
//           const SizedBox(height: 20),
//           _buildSendNotificationButton(),
//           const SizedBox(height: 20),
//           _buildNotificationHistoryCard(),
//         ],
//       ),
//     );
//   }

//   // Tab 3: System Statistics
//   Widget _buildSystemStatisticsTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildSystemStatsCard(),
//           const SizedBox(height: 20),
//           _buildUserStatsCard(),
//           const SizedBox(height: 20),
//           _buildTripStatsCard(),
//         ],
//       ),
//     );
//   }

//   // Notification Management Widgets
//   Widget _buildNotificationFormCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.notifications_active,
//                   color: Colors.blue.shade700, size: 24),
//               const SizedBox(width: 12),
//               const Text(
//                 'إرسال إشعار جديد',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),

//           // Tab for custom vs static notifications
//           DefaultTabController(
//             length: 2,
//             child: Column(
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade100,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: const TabBar(
//                     labelColor: Colors.blue,
//                     unselectedLabelColor: Colors.grey,
//                     indicatorColor: Colors.blue,
//                     tabs: [
//                       Tab(text: 'إشعار مخصص'),
//                       Tab(text: 'إشعارات جاهزة'),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 SizedBox(
//                   height: 400,
//                   child: TabBarView(
//                     children: [
//                       _buildCustomNotificationForm(),
//                       _buildStaticNotificationForm(),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCustomNotificationForm() {
//     return Column(
//       children: [
//         TextField(
//           controller: _notificationTitleController,
//           decoration: const InputDecoration(
//             labelText: 'عنوان الإشعار',
//             hintText: 'أدخل عنوان الإشعار',
//             border: OutlineInputBorder(),
//           ),
//         ),
//         const SizedBox(height: 16),
//         TextField(
//           controller: _notificationMessageController,
//           maxLines: 3,
//           decoration: const InputDecoration(
//             labelText: 'محتوى الإشعار',
//             hintText: 'أدخل محتوى الإشعار',
//             border: OutlineInputBorder(),
//           ),
//         ),
//         const SizedBox(height: 16),
//         TextField(
//           controller: _autoDeleteHoursController,
//           keyboardType: TextInputType.number,
//           decoration: const InputDecoration(
//             labelText: 'وقت الحذف التلقائي (بالساعات)',
//             hintText: '24',
//             border: OutlineInputBorder(),
//             suffixText: 'ساعة',
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStaticNotificationForm() {
//     final notificationTypes = _notificationService.getAdminNotificationTypes();

//     return ListView.builder(
//       itemCount: notificationTypes.length,
//       itemBuilder: (context, index) {
//         final notification = notificationTypes[index];
//         return Card(
//           margin: const EdgeInsets.only(bottom: 12),
//           child: ListTile(
//             leading: Text(
//               notification['icon'],
//               style: const TextStyle(fontSize: 24),
//             ),
//             title: Text(
//               notification['title'],
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(notification['message']),
//                 const SizedBox(height: 4),
//                 Text(
//                   notification['description'],
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//               ],
//             ),
//             trailing: ElevatedButton(
//               onPressed: () => _sendStaticNotification(notification['type']),
//               child: const Text('إرسال'),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildNotificationTargetingCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.my_location, color: Colors.green.shade700, size: 24),
//               const SizedBox(width: 12),
//               const Text(
//                 'استهداف المستخدمين',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           Obx(() => CheckboxListTile(
//                 title: const Text('إرسال لجميع المستخدمين'),
//                 value: _sendToAllUsers.value,
//                 onChanged: (value) {
//                   _sendToAllUsers.value = value ?? true;
//                 },
//               )),
//           const SizedBox(height: 16),
//           const Text(
//             'أنواع المستخدمين:',
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Obx(() => Column(
//                 children: [
//                   CheckboxListTile(
//                     title: const Text('الركاب'),
//                     value: _selectedUserTypes.contains('rider'),
//                     onChanged: (value) {
//                       if (value == true) {
//                         _selectedUserTypes.add('rider');
//                       } else {
//                         _selectedUserTypes.remove('rider');
//                       }
//                     },
//                   ),
//                   CheckboxListTile(
//                     title: const Text('السائقين'),
//                     value: _selectedUserTypes.contains('driver'),
//                     onChanged: (value) {
//                       if (value == true) {
//                         _selectedUserTypes.add('driver');
//                       } else {
//                         _selectedUserTypes.remove('driver');
//                       }
//                     },
//                   ),
//                 ],
//               )),
//         ],
//       ),
//     );
//   }

//   Widget _buildSendNotificationButton() {
//     return Obx(() => SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: _isSendingNotification.value ? null : _sendNotification,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: _isSendingNotification.value
//                 ? const Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           valueColor:
//                               AlwaysStoppedAnimation<Color>(Colors.white),
//                         ),
//                       ),
//                       SizedBox(width: 12),
//                       Text('جاري الإرسال...'),
//                     ],
//                   )
//                 : const Text(
//                     'إرسال الإشعار',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//           ),
//         ));
//   }

//   Widget _buildNotificationHistoryCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.history, color: Colors.orange.shade700, size: 24),
//               const SizedBox(width: 12),
//               const Text(
//                 'سجل الإشعارات',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           // Notification History List
//           SizedBox(
//             height: 200,
//             child: ListView.builder(
//               itemCount: 5,
//               itemBuilder: (context, index) {
//                 final notifications = [
//                   {
//                     'title': '🎉 مرحباً بك في تطبيق النقل',
//                     'time': 'منذ ساعتين',
//                     'status': 'تم الإرسال',
//                     'color': Colors.green,
//                   },
//                   {
//                     'title': '🔧 صيانة مجدولة',
//                     'time': 'منذ 5 ساعات',
//                     'status': 'تم الإرسال',
//                     'color': Colors.orange,
//                   },
//                   {
//                     'title': '📱 تحديث جديد متاح',
//                     'time': 'منذ يوم',
//                     'status': 'تم الإرسال',
//                     'color': Colors.blue,
//                   },
//                   {
//                     'title': '🎁 عرض خاص',
//                     'time': 'منذ يومين',
//                     'status': 'تم الإرسال',
//                     'color': Colors.purple,
//                   },
//                   {
//                     'title': '⚠️ تنبيه مهم',
//                     'time': 'منذ أسبوع',
//                     'status': 'تم الإرسال',
//                     'color': Colors.red,
//                   },
//                 ];

//                 final notification = notifications[index];
//                 final color = notification['color'] as Color;
//                 final title = notification['title'] as String;
//                 final time = notification['time'] as String;
//                 final status = notification['status'] as String;

//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 8),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: color.withOpacity(0.1),
//                       child: Icon(
//                         Icons.notifications,
//                         color: color,
//                         size: 20,
//                       ),
//                     ),
//                     title: Text(
//                       title,
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                     subtitle: Text(
//                       time,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                     trailing: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: color.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         status,
//                         style: TextStyle(
//                           fontSize: 10,
//                           color: color,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // System Statistics Widgets
//   Widget _buildSystemStatsCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.analytics, color: Colors.purple.shade700, size: 24),
//               const SizedBox(width: 12),
//               const Text(
//                 'إحصائيات النظام',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),

//           // System Statistics Grid
//           GridView.count(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             crossAxisCount: 2,
//             crossAxisSpacing: 16,
//             mainAxisSpacing: 16,
//             childAspectRatio: 1.5,
//             children: [
//               _buildStatCard(
//                 icon: Icons.speed,
//                 title: 'سرعة النظام',
//                 value: '98%',
//                 color: Colors.green,
//               ),
//               _buildStatCard(
//                 icon: Icons.storage,
//                 title: 'استخدام التخزين',
//                 value: '2.3 GB',
//                 color: Colors.blue,
//               ),
//               _buildStatCard(
//                 icon: Icons.wifi,
//                 title: 'حالة الخادم',
//                 value: 'متصل',
//                 color: Colors.green,
//               ),
//               _buildStatCard(
//                 icon: Icons.security,
//                 title: 'الأمان',
//                 value: 'محمي',
//                 color: Colors.green,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard({
//     required IconData icon,
//     required String title,
//     required String value,
//     required Color color,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, color: color, size: 32),
//           const SizedBox(height: 8),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey.shade600,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUserStatsCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.people, color: Colors.teal.shade700, size: 24),
//               const SizedBox(width: 12),
//               const Text(
//                 'إحصائيات المستخدمين',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),

//           // User Statistics Grid
//           GridView.count(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             crossAxisCount: 2,
//             crossAxisSpacing: 16,
//             mainAxisSpacing: 16,
//             childAspectRatio: 1.5,
//             children: [
//               _buildStatCard(
//                 icon: Icons.person,
//                 title: 'إجمالي المستخدمين',
//                 value: '1,247',
//                 color: Colors.blue,
//               ),
//               _buildStatCard(
//                 icon: Icons.directions_car,
//                 title: 'السائقين النشطين',
//                 value: '89',
//                 color: Colors.green,
//               ),
//               _buildStatCard(
//                 icon: Icons.people,
//                 title: 'الركاب النشطين',
//                 value: '1,158',
//                 color: Colors.orange,
//               ),
//               _buildStatCard(
//                 icon: Icons.trending_up,
//                 title: 'نمو شهري',
//                 value: '+12%',
//                 color: Colors.purple,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTripStatsCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.local_taxi, color: Colors.indigo.shade700, size: 24),
//               const SizedBox(width: 12),
//               const Text(
//                 'إحصائيات الرحلات',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),

//           // Trip Statistics Grid
//           GridView.count(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             crossAxisCount: 2,
//             crossAxisSpacing: 16,
//             mainAxisSpacing: 16,
//             childAspectRatio: 1.5,
//             children: [
//               _buildStatCard(
//                 icon: Icons.local_taxi,
//                 title: 'رحلات اليوم',
//                 value: '156',
//                 color: Colors.green,
//               ),
//               _buildStatCard(
//                 icon: Icons.attach_money,
//                 title: 'إيرادات اليوم',
//                 value: '2,450 ج.م',
//                 color: Colors.blue,
//               ),
//               _buildStatCard(
//                 icon: Icons.star,
//                 title: 'متوسط التقييم',
//                 value: '4.8',
//                 color: Colors.orange,
//               ),
//               _buildStatCard(
//                 icon: Icons.timer,
//                 title: 'متوسط وقت الرحلة',
//                 value: '18 دقيقة',
//                 color: Colors.purple,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // Notification Methods
//   Future<void> _sendNotification() async {
//     try {
//       _isSendingNotification.value = true;

//       final title = _notificationTitleController.text.trim();
//       final message = _notificationMessageController.text.trim();
//       final autoDeleteHours =
//           int.tryParse(_autoDeleteHoursController.text) ?? 24;

//       if (title.isEmpty || message.isEmpty) {
//         Get.snackbar(
//           'خطأ',
//           'يرجى ملء جميع الحقول المطلوبة',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//         );
//         return;
//       }

//       await _notificationService.sendAdminMessageWithAutoDelete(
//         title: title,
//         message: message,
//         autoDeleteAfter: Duration(hours: autoDeleteHours),
//         targetUserIds: _sendToAllUsers.value
//             ? null
//             : [], // TODO: إضافة قائمة المستخدمين المستهدفين
//       );

//       // Clear form
//       _notificationTitleController.clear();
//       _notificationMessageController.clear();
//       _autoDeleteHoursController.text = '24';

//       Get.snackbar(
//         'نجح',
//         'تم إرسال الإشعار بنجاح',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//       );
//     } catch (e) {
//       Get.snackbar(
//         'خطأ',
//         'تعذر إرسال الإشعار: $e',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     } finally {
//       _isSendingNotification.value = false;
//     }
//   }

//   Future<void> _sendStaticNotification(dynamic notificationType) async {
//     try {
//       _isSendingNotification.value = true;

//       await _notificationService.sendStaticAdminNotification(
//         type: notificationType,
//         targetUserIds: _sendToAllUsers.value
//             ? null
//             : [], // TODO: إضافة قائمة المستخدمين المستهدفين
//       );

//       Get.snackbar(
//         'نجح',
//         'تم إرسال الإشعار الجاهز بنجاح',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//       );
//     } catch (e) {
//       Get.snackbar(
//         'خطأ',
//         'تعذر إرسال الإشعار: $e',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     } finally {
//       _isSendingNotification.value = false;
//     }
//   }

//   // Driver Management Widgets
//   Widget _buildDriverManagementHeader() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.people, color: Colors.blue.shade700, size: 28),
//               const SizedBox(width: 12),
//               const Text(
//                 'إدارة السائقين',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'مراجعة وإدارة طلبات السائقين الجدد',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey.shade600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDriverStatsCards() {
//     return Row(
//       children: [
//         Expanded(
//           child: _buildDriverStatCard(
//             'في الانتظار',
//             '12',
//             Icons.pending,
//             Colors.orange,
//           ),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: _buildDriverStatCard(
//             'موافق عليهم',
//             '89',
//             Icons.check_circle,
//             Colors.green,
//           ),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: _buildDriverStatCard(
//             'مرفوضين',
//             '5',
//             Icons.cancel,
//             Colors.red,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDriverStatCard(
//       String title, String count, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: color, size: 32),
//           const SizedBox(height: 12),
//           Text(
//             count,
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade600,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDriverManagementActions() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'إجراءات سريعة',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 20),
//           Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: () => _navigateToDriverManagement(),
//                   icon: const Icon(Icons.people),
//                   label: const Text('إدارة السائقين'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: () => _sendBulkNotification(),
//                   icon: const Icon(Icons.notifications),
//                   label: const Text('إشعار جماعي'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: () => Get.toNamed('/image-upload-settings'),
//                   icon: const Icon(Icons.cloud_upload),
//                   label: const Text('إعدادات رفع الصور'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.purple,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecentDriverApplications() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Text(
//                 'آخر الطلبات',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const Spacer(),
//               TextButton(
//                 onPressed: () => _navigateToDriverManagement(),
//                 child: const Text('عرض الكل'),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           _buildDriverApplicationItem(
//             'أحمد محمد',
//             '0123456789',
//             'منذ ساعتين',
//             'pending',
//           ),
//           _buildDriverApplicationItem(
//             'فاطمة علي',
//             '0123456790',
//             'منذ 3 ساعات',
//             'pending',
//           ),
//           _buildDriverApplicationItem(
//             'محمد حسن',
//             '0123456791',
//             'منذ 5 ساعات',
//             'pending',
//           ),
//           const SizedBox(height: 16),
//           Center(
//             child: ElevatedButton.icon(
//               onPressed: () => _navigateToDriverManagement(),
//               icon: const Icon(Icons.people),
//               label: const Text('عرض جميع الطلبات'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDriverApplicationItem(
//       String name, String phone, String time, String status) {
//     Color statusColor;
//     String statusText;
//     IconData statusIcon;

//     switch (status) {
//       case 'pending':
//         statusColor = Colors.orange;
//         statusText = 'في الانتظار';
//         statusIcon = Icons.pending;
//         break;
//       case 'approved':
//         statusColor = Colors.green;
//         statusText = 'موافق عليه';
//         statusIcon = Icons.check_circle;
//         break;
//       case 'rejected':
//         statusColor = Colors.red;
//         statusText = 'مرفوض';
//         statusIcon = Icons.cancel;
//         break;
//       default:
//         statusColor = Colors.grey;
//         statusText = 'غير محدد';
//         statusIcon = Icons.help;
//     }

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             backgroundColor: Colors.blue.shade100,
//             child: Text(
//               name.substring(0, 1),
//               style: TextStyle(
//                 color: Colors.blue.shade700,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   name,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   phone,
//                   style: TextStyle(
//                     color: Colors.grey.shade600,
//                     fontSize: 14,
//                   ),
//                 ),
//                 Text(
//                   time,
//                   style: TextStyle(
//                     color: Colors.grey.shade500,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: statusColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: statusColor.withOpacity(0.3)),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(statusIcon, size: 16, color: statusColor),
//                 const SizedBox(width: 4),
//                 Text(
//                   statusText,
//                   style: TextStyle(
//                     color: statusColor,
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _openDriverManagement() {
//     Get.toNamed('/admin/driver-management');
//   }

//   void _navigateToDriverManagement() {
//     Get.toNamed('/admin/driver-management');
//   }

//   void _sendBulkNotification() {
//     Get.snackbar(
//       'قريباً',
//       'سيتم إضافة ميزة الإشعار الجماعي قريباً',
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.orange,
//       colorText: Colors.white,
//     );
//   }
// }

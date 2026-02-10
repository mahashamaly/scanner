import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanner/widgets/snap_dropdown_field.dart';
import 'package:scanner/widgets/snap_text_field.dart';


class EmployeeDetailsForm extends StatelessWidget {
  //القيمة المختارة حاليا من التصنيف
  final String? mainCategoryValue;
  //دالة  تنفذ لما المستخدم يغير القيمة
  final ValueChanged<String?>? onMainCategoryChanged;
  
  final String? subCategoryValue;
  final ValueChanged<String?>? onSubCategoryChanged;

  final String? fileClassValue; 
  final ValueChanged<String?>? onFileClassChanged;

  final TextEditingController penaltyDateController;
  final TextEditingController jobTitleController;
  final TextEditingController penaltyReasonController;
  final TextEditingController penaltyDurationController;
  
  final bool isScanning;
  final VoidCallback onSave;

  const EmployeeDetailsForm({
    super.key,
    required this.mainCategoryValue,
    required this.onMainCategoryChanged,
    required this.subCategoryValue,
    required this.onSubCategoryChanged,
    required this.fileClassValue,
    required this.onFileClassChanged,
    required this.penaltyDateController,
    required this.jobTitleController,
    required this.penaltyReasonController,
    required this.penaltyDurationController,
    required this.isScanning,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        // Reduced padding for better mobile fit
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "بيانات المخالفة",
              style: GoogleFonts.cairo(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "يرجى مراجعة البيانات المستخرجة أدناه.",
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            
            // Row 1: Main Category and Sub Category
            Row(
              children: [
                Expanded(
                  child: SnapDropdownField(
                    label: "التصنيف الرئيسي :",
                    items: const ["اختر التصنيف الرئيسي", "شهادة علمية","ملف صحى","عقوبات","كشوفات ومراسلات"],
                    value: mainCategoryValue,
                    onChanged: onMainCategoryChanged,
                    hintText: "اختر...",
                    isScanning: isScanning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SnapDropdownField(
                    label: "التصنيف الفرعي :",
                    items: const ["اختر التصنيف الفرعي", "كشوفات ومراسلات","تفيم سنوي","نوع العقوبة","أمر اداري","كتاب شكر وتقدير"],
                    value: subCategoryValue,
                    onChanged: onSubCategoryChanged,
                    hintText: "اختر...",
                    isScanning: isScanning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Row 2: File Classification (Dropdown)
            SnapDropdownField(
              label: "تصنيف الملف :",
              items: const ["قرارات", "مكاتبات وكشوفات", "تنبيه", "لفت نظر", "إنذار"],
              value: fileClassValue,
              onChanged: onFileClassChanged,
              hintText: "اختر تصنيف الملف...",
              isScanning: isScanning,
            ),
            
            const SizedBox(height: 20),

            // Row 3: Date and Job Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SnapTextField(
                    label: "تاريخ العقوبة",
                    controller: penaltyDateController,
                    isScanning: isScanning,
                    hintText: "YYYY-MM-DD",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SnapTextField(
                    label: "المسمى الوظيفي",
                    controller: jobTitleController,
                    isScanning: isScanning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Row 4: Penalty Reason
            SnapTextField(
              label: "سبب العقوبة",
              controller: penaltyReasonController,
              isScanning: isScanning,
            ),

            const SizedBox(height: 20),

            // Row 5: Duration
             SnapTextField(
              label: "مدة البقاء على العقوبة",
              controller: penaltyDurationController,
              isScanning: isScanning,
            ),

            const SizedBox(height: 40),
            
            // Save Button (Full Width)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), // Emerald Green
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "حفظ السجل",
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

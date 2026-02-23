import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategorySelectionSection extends StatelessWidget {
  final String? selectedMainCategory;
  final String? selectedSubCategory;
  final String? selectedFileClassification;
  final List<String> mainCategories;
  final List<String> subCategories;
  final List<String> fileClassifications;
  final Function(String?) onMainCategoryChanged;
  final Function(String?) onSubCategoryChanged;
  final Function(String?) onFileClassificationChanged;

  const CategorySelectionSection({
    super.key,
    required this.selectedMainCategory,
    required this.selectedSubCategory,
    required this.selectedFileClassification,
    required this.mainCategories,
    required this.subCategories,
    required this.fileClassifications,
    required this.onMainCategoryChanged,
    required this.onSubCategoryChanged,
    required this.onFileClassificationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📂 اختر نوع المستند',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // التصنيف الرئيسي
          _buildDropdown(
            label: 'التصنيف الرئيسي',
            value: selectedMainCategory,
            items: mainCategories,
            onChanged: onMainCategoryChanged,
          ),
          const SizedBox(height: 16),

          // التصنيف الفرعي
          if (subCategories.isNotEmpty)
            _buildDropdown(
              label: 'التصنيف الفرعي',
              value: selectedSubCategory,
              items: subCategories,
              onChanged: onSubCategoryChanged,
            ),
          const SizedBox(height: 16),

          // تصنيف الملف
          if (fileClassifications.isNotEmpty)
            _buildDropdown(
              label: 'تصنيف الملف',
              value: selectedFileClassification,
              items: fileClassifications,
              onChanged: onFileClassificationChanged,
            ),
        ],
      ),
    );
  }

  /// بناء قائمة منسدلة
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111328),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF111328),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              hint: Text(
                'اختر $label',
                style: GoogleFonts.cairo(color: Colors.white38),
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.cairo(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

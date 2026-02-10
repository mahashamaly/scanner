import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SnapDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final String hintText;
  final bool isScanning;

  const SnapDropdownField({
    super.key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    required this.hintText,
    this.isScanning = false,
  });

  @override
  Widget build(BuildContext context) {
    // Add textDirection: TextDirection.rtl to ensure right-to-left layout for Arabic
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo( // Cairo is better for Arabic
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              isExpanded: true, 
              //لتخفيف الارتفاع
              isDense: true, 
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis, // Add ellipsis for long text
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111827),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                hintText: hintText,
                hintStyle: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                ),
                //لتوفير مساحة للنص والايقونة داخل الحقل، يعطي راحة بصرية.
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Slightly reduced padding
              ),
            ),
          ),
        ],
      ),
    );
  }
}

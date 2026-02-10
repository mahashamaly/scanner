import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class SnapTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon; // Icon is optional now as per the new design image
  final bool isScanning;
  final String hintText;

  const SnapTextField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.isScanning = false,
    this.hintText = "...",
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Container(
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
                child: TextField(
                  controller: controller,
                  readOnly: false, // Allow editing of extracted data
                  textAlign: TextAlign.right, // RTL text alignment
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111827),
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB), // Very light gray background
                    hintText: hintText,
                    hintStyle: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 14),
                    // Only show prefixIcon if icon is provided
                    prefixIcon: icon != null ? Icon(icon, color: Colors.grey[400], size: 20) : null,
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                ),
              );
            },
          ).animate(target: isScanning ? 0 : 1).fadeIn(duration: 300.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

class DocumentUploadArea extends StatelessWidget {
  final XFile? selectedImage;
  final bool isScanning;
  final VoidCallback onPickImage;

  const DocumentUploadArea({
    super.key,
    required this.selectedImage,
    required this.isScanning,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEF2F6),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isScanning ? const Color(0xFF4F46E5) : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  //هنا فى حالة فى صورة(المستخدم رفع مستند)
                  if (selectedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        //عرض الصورة من المسار
                        File(selectedImage!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      
                        errorBuilder: (context, error, stackTrace) =>
                             const Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey)),
                      ),
                    ).animate().fadeIn(duration: 500.ms)
               //هنا حالة فش صورة
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "No Document Selected",
                          style: GoogleFonts.inter(
                            color: Colors.grey[500],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                  // Scanning Overlay with Laser Effect
                  if (isScanning)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.black.withOpacity(0.3),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                // Futuristic Grid Overlay
                                Opacity(
                                  opacity: 0.1,
                                  child: GridView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 10,
                                    ),
                                    itemBuilder: (context, index) => Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.white, width: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // The Moving Laser Line
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF6366F1).withOpacity(0.9),
                                          blurRadius: 20,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF6366F1).withOpacity(0),
                                          const Color(0xFF6366F1),
                                          const Color(0xFF6366F1).withOpacity(0),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                    .animate(onPlay: (controller) => controller.repeat())
                                    .moveY(
                                      begin: 0,
                                      end: constraints.maxHeight,
                                      duration: 2000.ms,
                                      curve: Curves.easeInOut,
                                    ),
                                
                                // Center Icon with Pulse
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6366F1).withOpacity(0.2),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)),
                                        ),
                                        child: const Icon(
                                          Icons.psychology_outlined,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                      )
                                          .animate(onPlay: (controller) => controller.repeat())
                                          .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1000.ms)
                                          .then()
                                          .scale(begin: const Offset(1.1, 1.1), end: const Offset(0.9, 0.9), duration: 1000.ms),
                                      const SizedBox(height: 16),
                                      Text(
                                        "AI Intelligence Scanning...",
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 0.5,
                                        ),
                                      ).animate(onPlay: (controller) => controller.repeat()).fadeIn(duration: 800.ms).then().fadeOut(duration: 800.ms),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: isScanning ? null : onPickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5), // Indigo
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(
                selectedImage != null ? "Retake / Change" : "Upload Document",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ImageCaptureSection extends StatefulWidget {
  final List<File> selectedImages;
  final bool isProcessing;
  final Function(ImageSource) onImagePicked;
  final Function(int) onImageRemoved;
  final VoidCallback? onStartScan;

  const ImageCaptureSection({
    super.key,
    required this.selectedImages,
    required this.isProcessing,
    required this.onImagePicked,
    required this.onImageRemoved,
    this.onStartScan,
  });

  @override
  State<ImageCaptureSection> createState() => _ImageCaptureSectionState();
}

class _ImageCaptureSectionState extends State<ImageCaptureSection> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void didUpdateWidget(ImageCaptureSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedImages.length > oldWidget.selectedImages.length) {
      // تم إضافة صورة جديدة، انتقل إليها
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            widget.selectedImages.length - 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
        children: [
          // العنوان
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, color: Color(0xFFEB1555), size: 28),
              const SizedBox(width: 12),
              Text(
                'صور المستند',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك إضافة عدة صفحات للمستند الواحد',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // عرض الصور المختارة
          if (widget.selectedImages.isNotEmpty)
            Container(
              height: 300,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEB1555), width: 2),
                          image: DecorationImage(
                            image: FileImage(widget.selectedImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // زر حذف الصورة
                      if (!widget.isProcessing)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: GestureDetector(
                            onTap: () => widget.onImageRemoved(index),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      // رقم الصفحة
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'صفحة ${index + 1} من ${widget.selectedImages.length}',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          // أزرار اختيار الصورة (أو إضافة المزيد)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isProcessing
                      ? null
                      : () => widget.onImagePicked(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 24),
                  label: Text(
                    widget.selectedImages.isEmpty ? 'تصوير مستند' : 'إضافة صفحة',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEB1555),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isProcessing
                      ? null
                      : () => widget.onImagePicked(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 24),
                  label: Text(
                    widget.selectedImages.isEmpty ? 'من المعرض' : 'إضافة من المعرض',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C4F5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // زر بدء المسح الذكي
          if (widget.selectedImages.isNotEmpty && !widget.isProcessing)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onStartScan,
                  icon: const Icon(Icons.auto_awesome, size: 24),
                  label: Text(
                    'بدء المسح الذكي لجميع الصفحات',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853), // لون أخضر مميز للتحليل
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFF00C853).withOpacity(0.5),
                  ),
                ),
              ),
            ),

          // مؤشر التحميل
          if (widget.isProcessing)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFFEB1555),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '🤖 جاري تحليل المستند المكون من ${widget.selectedImages.length} صفحات...',
                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

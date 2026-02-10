
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanner/services/gemini_service.dart';
import 'package:scanner/widgets/document_upload_area.dart';
import 'package:scanner/widgets/employee_details_form.dart';

// Gemini AI Service for better accuracy





class SnapFillScreen extends StatefulWidget {
  const SnapFillScreen({super.key});

  @override
  State<SnapFillScreen> createState() => _SnapFillScreenState();
}

class _SnapFillScreenState extends State<SnapFillScreen> {
  // Dropdowns
  String? _mainCategory = "اختر التصنيف الرئيسي";
  String? _subCategory = "اختر التصنيف الفرعي";
  String? _fileClass;

  // Text Controllers
  final TextEditingController _penaltyDateController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _penaltyReasonController = TextEditingController();
  final TextEditingController _penaltyDurationController = TextEditingController();

  // Image & Loading State
  XFile? _selectedImage;
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _penaltyDateController.dispose();
    _jobTitleController.dispose();
    _penaltyReasonController.dispose();
    _penaltyDurationController.dispose();
    super.dispose();
  }



  // --- معالجة الصورة عبر Gemini AI (دقة أعلى) ---
  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() => _isScanning = true);

    try {
      // استخدام Gemini Service
      final geminiService = GeminiService();
      final extractedData = await geminiService.processDocument(_selectedImage!.path);

      debugPrint("Extracted Data: $extractedData");

      // تحديث الحقول بالبيانات المستخرجة
      if (mounted) {
        setState(() {
          final fields = extractedData['fields'] as Map<String, dynamic>? ?? {};

          // تحديث الحقول النصية (باستخدام المسميات الجديدة snake_case)
          _penaltyDateController.text = fields['penalty_date']?.toString() ?? '';
          _jobTitleController.text = fields['job_title']?.toString() ?? '';
          _penaltyReasonController.text = fields['penalty_reason']?.toString() ?? '';
          _penaltyDurationController.text = fields['penalty_duration']?.toString() ?? '';
          
          // قوائم الخيارات المتاحة (يجب أن تتطابق مع EmployeeDetailsForm)
          const mainCategories = ["اختر التصنيف الرئيسي", "شهادة علمية", "ملف صحى", "عقوبات", "كشوفات ومراسلات"];
          const subCategories = ["اختر التصنيف الفرعي", "كشوفات ومراسلات", "تفيم سنوي", "نوع العقوبة", "أمر اداري", "كتاب شكر وتقدير"];
          const fileClasses = ["قرارات", "مكاتبات وكشوفات", "تنبيه", "لفت نظر", "إنذار"];

          // تحديث القوائم المنسدلة بناءً على الاستخراج (مع التحقق من وجود القيمة في القائمة)
          if (extractedData['mainCategory'] != null && mainCategories.contains(extractedData['mainCategory'])) {
            _mainCategory = extractedData['mainCategory'];
          }
          if (extractedData['subCategory'] != null && subCategories.contains(extractedData['subCategory'])) {
            _subCategory = extractedData['subCategory'];
          }
          if (extractedData['fileClass'] != null && fileClasses.contains(extractedData['fileClass'])) {
            _fileClass = extractedData['fileClass'];
          }

          _isScanning = false;
        });
        _showSnackBar("✅ تم استخراج البيانات بنجاح");
      }
    } catch (e) {
      debugPrint("Processing Error: $e");
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        _showSnackBar("⚠️ فشل الاستخراج: تأكد من وضوح الصورة والاتصال", isError: true);
      }
    }
  }


  // --- اختيار الصورة من الكاميرا أو المعرض ---
  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("اختر طريقة الإدخال", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(Icons.camera_alt_rounded, "التقاط صورة", () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                }, color: Colors.green),
                _buildSourceOption(Icons.image, "اختيار من المعرض", () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                }, color: Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(IconData icon, String label, VoidCallback onTap, {Color color = Colors.blue}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 35, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() => _selectedImage = image);
      _processImage(); // بدء المعالجة فور اختيار الصورة
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("SnapFill AI Scan", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // منطقة رفع وعرض الصورة
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 350),
              child: DocumentUploadArea(
                selectedImage: _selectedImage,
                isScanning: _isScanning,
                onPickImage: _showImageSourceActionSheet,
              ),
            ),
            const SizedBox(height: 25),
            // نموذج البيانات (Form)
            EmployeeDetailsForm(
              mainCategoryValue: _mainCategory,
              onMainCategoryChanged: (val) => setState(() => _mainCategory = val),
              subCategoryValue: _subCategory,
              onSubCategoryChanged: (val) => setState(() => _subCategory = val),
              fileClassValue: _fileClass,
              onFileClassChanged: (val) => setState(() => _fileClass = val),
              penaltyDateController: _penaltyDateController,
              jobTitleController: _jobTitleController,
              penaltyReasonController: _penaltyReasonController,
              penaltyDurationController: _penaltyDurationController,
              isScanning: _isScanning,
              onSave: () => _showSnackBar("تم حفظ البيانات بنجاح"),
            ),
          ],
        ),
      ),
    );
  }
}


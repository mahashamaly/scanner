import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../services/gemini_service.dart';
import '../widgets/image_capture_section.dart';
import '../widgets/category_selection_section.dart';
import '../widgets/dynamic_form_section.dart';

class DynamicArchivePage extends StatefulWidget {
  const DynamicArchivePage({super.key});

  @override
  State<DynamicArchivePage> createState() => _DynamicArchivePageState();
}

class _DynamicArchivePageState extends State<DynamicArchivePage> {
  // القوائم المنسدلة
  String? selectedMainCategory;
  String? selectedSubCategory;
  String? selectedFileClassification;

  // القوائم المتاحة
  List<String> mainCategories = [];
  List<String> subCategories = [];
  List<String> fileClassifications = [];

  // الحقول الديناميكية
  List<DynamicField> dynamicFields = [];
  Map<String, TextEditingController> fieldControllers = {};

  // الصور المختارة
  List<File> selectedImages = [];
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadMainCategories();
  }

  @override
  void dispose() {
    // تنظيف الـ controllers
    for (var controller in fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// تحميل التصنيفات الرئيسية
  Future<void> _loadMainCategories() async {
    final categories = await CategoryService.getMainCategories();
    setState(() {
      mainCategories = categories;
    });
  }

  /// عند اختيار التصنيف الرئيسي
  Future<void> _onMainCategoryChanged(String? value) async {
    if (value == null) return;

    setState(() {
      selectedMainCategory = value;
      selectedSubCategory = null;
      selectedFileClassification = null;
      subCategories = [];
      fileClassifications = [];
      dynamicFields = [];
      _clearControllers();
    });

    final subs = await CategoryService.getSubCategories(value);
    setState(() {
      subCategories = subs;
    });
  }

  /// عند اختيار التصنيف الفرعي
  Future<void> _onSubCategoryChanged(String? value) async {
    if (value == null || selectedMainCategory == null) return;

    setState(() {
      selectedSubCategory = value;
      selectedFileClassification = null;
      fileClassifications = [];
      dynamicFields = [];
      _clearControllers();
    });

    final files = await CategoryService.getFileClassifications(
      selectedMainCategory!,
      value,
    );
    setState(() {
      fileClassifications = files;
    });
  }

  /// عند اختيار تصنيف الملف
  Future<void> _onFileClassificationChanged(String? value) async {
    if (value == null ||
        selectedMainCategory == null ||
        selectedSubCategory == null) {
      return;
    }

    setState(() {
      selectedFileClassification = value;
      dynamicFields = [];
      _clearControllers();
    });

    final fields = await CategoryService.getFields(
      selectedMainCategory!,
      selectedSubCategory!,
      value,
    );

    setState(() {
      dynamicFields = fields;
      // إنشاء controllers للحقول
      for (var field in fields) {
        fieldControllers[field.id] = TextEditingController();
      }
    });
  }

  /// تنظيف الـ controllers
  void _clearControllers() {
    for (var controller in fieldControllers.values) {
      controller.dispose();
    }
    fieldControllers.clear();
  }

  /// اختيار صورة من الكاميرا أو المعرض
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        selectedImages.add(File(pickedFile.path));
      });
    }
  }

  /// حذف صورة
  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  /// البحث عن أقرب تطابق في قائمة مع مراعاة خصائص اللغة العربية
  String? _findBestMatch(String searchTerm, List<String> options) {
    if (searchTerm.isEmpty || options.isEmpty) return null;

    // دالة لتنظيف النص العربي وتوحيده
    String normalize(String text) {
      return text
          .replaceAll('ال', '') // إزالة ال التعريف
          .replaceAll('أ', 'ا') // توحيد الألف
          .replaceAll('إ', 'ا')
          .replaceAll('آ', 'ا')
          .replaceAll('ة', 'ه') // توحيد التاء المربوطة والهاء
          .replaceAll('ى', 'ي') // توحيد الياء والألف المقصورة
          .replaceAll(RegExp(r'\s+'), '') // إزالة المسافات
          .trim();
    }

    final normalizedSearch = normalize(searchTerm);

    // 1. البحث عن تطابق دقيق أولاً
    for (var option in options) {
      if (option.trim() == searchTerm.trim()) return option;
    }

    // 2. البحث عن تطابق بعد التوحيد 
    for (var option in options) {
      if (normalize(option) == normalizedSearch) {
        debugPrint("🔍 تطابق بعد التوحيد: '$searchTerm' ≈ '$option'");
        return option;
      }
    }

    // 3. البحث عن تطابق جزئي بعد التوحيد
    for (var option in options) {
      final normalizedOption = normalize(option);
      if (normalizedOption.contains(normalizedSearch) ||
          normalizedSearch.contains(normalizedOption)) {
        debugPrint("🔍 تطابق جزئي بعد التوحيد: '$searchTerm' ≈ '$option'");
        return option;
      }
    }

    return null;
  }

  /// تحليل الصورة وتحديد التصنيفات والحقول تلقائياً
  Future<void> _analyzeImageAndPopulateFields() async {
    if (selectedImages.isEmpty) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final geminiService = GeminiService();
      
      // استخراج البيانات الأولية من الصور
      final extractedData = await geminiService.processDocument(
        selectedImages.map((e) => e.path).toList(),
      );
      
      debugPrint("📊 البيانات المستخرجة: $extractedData");

      // تحديد التصنيفات بناءً على البيانات المستخرجة
      final mainCat = extractedData['mainCategory'] ?? '';
      final subCat = extractedData['subCategory'] ?? '';
      final fileCat = extractedData['fileClass'] ?? '';

      debugPrint("🔎 البحث عن: mainCat='$mainCat', subCat='$subCat', fileCat='$fileCat'");

      // تحميل التصنيفات المتاحة
      await _loadMainCategories();
      debugPrint("📋 التصنيفات الرئيسية المتاحة: $mainCategories");

      // البحث عن أقرب تطابق للتصنيف الرئيسي
      final matchedMainCat = _findBestMatch(mainCat, mainCategories);
      
      if (matchedMainCat != null) {
        debugPrint("✅ تم العثور على التصنيف الرئيسي: $matchedMainCat");
        await _onMainCategoryChanged(matchedMainCat);
        debugPrint("📋 التصنيفات الفرعية المتاحة: $subCategories");
        
        // البحث عن أقرب تطابق للتصنيف الفرعي
        final matchedSubCat = _findBestMatch(subCat, subCategories);
        
        if (matchedSubCat != null) {
          debugPrint("✅ تم العثور على التصنيف الفرعي: $matchedSubCat");
          await _onSubCategoryChanged(matchedSubCat);
          debugPrint("📋 تصنيفات الملف المتاحة: $fileClassifications");
          
          // البحث عن أقرب تطابق لتصنيف الملف
          final matchedFileCat = _findBestMatch(fileCat, fileClassifications);
          
          if (matchedFileCat != null) {
            debugPrint("✅ تم العثور على تصنيف الملف: $matchedFileCat");
            await _onFileClassificationChanged(matchedFileCat);
            
            // ملء الحقول بالبيانات المستخرجة
            debugPrint("📝 ملء الحقول: ${fieldControllers.keys.toList()}");
            setState(() {
              final fields = extractedData['fields'] as Map<String, dynamic>? ?? {};
              for (var entry in fields.entries) {
                if (fieldControllers.containsKey(entry.key) && fieldControllers[entry.key] != null) {
                  fieldControllers[entry.key]!.text = entry.value.toString();
                  debugPrint("✏️ تم ملء الحقل '${entry.key}' بالقيمة '${entry.value}'");
                } else {
                  debugPrint("⚠️ الحقل '${entry.key}' غير موجود في النماذج الحالية، تم تخطيه.");
                }
              }
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ تم تحليل المستند وملء الحقول بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            debugPrint("⚠️ لم يتم العثور على تطابق لتصنيف الملف: $fileCat");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ لم يتم العثور على تصنيف الملف: $fileCat'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          debugPrint("⚠️ لم يتم العثور على تطابق للتصنيف الفرعي: $subCat");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ لم يتم العثور على التصنيف الفرعي: $subCat'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        debugPrint("⚠️ لم يتم العثور على تطابق للتصنيف الرئيسي: $mainCat");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ لم يتم العثور على التصنيف الرئيسي: $mainCat'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ خطأ في تحليل المستند: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ في تحليل المستند: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  /// زر الحفظ
  void _onSave() {
    // هنا يمكن إضافة منطق الحفظ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💾 تم حفظ البيانات بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D1E33),
        elevation: 0,
        title: Text(
          'نظام الأرشفة الذكي',
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // قسم اختيار الصورة
            // قسم اختيار الصورة
            ImageCaptureSection(
              selectedImages: selectedImages,
              isProcessing: isProcessing,
              onImagePicked: _pickImage,
              onImageRemoved: _removeImage,
              onStartScan: _analyzeImageAndPopulateFields,
            ),
            const SizedBox(height: 32),

            // قسم التصنيفات
            if (selectedMainCategory != null) ...[
              CategorySelectionSection(
                selectedMainCategory: selectedMainCategory,
                selectedSubCategory: selectedSubCategory,
                selectedFileClassification: selectedFileClassification,
                mainCategories: mainCategories,
                subCategories: subCategories,
                fileClassifications: fileClassifications,
                onMainCategoryChanged: _onMainCategoryChanged,
                onSubCategoryChanged: _onSubCategoryChanged,
                onFileClassificationChanged: _onFileClassificationChanged,
              ),
              const SizedBox(height: 32),
            ],

            // قسم الحقول الديناميكية
            if (dynamicFields.isNotEmpty) ...[
              DynamicFormSection(
                fields: dynamicFields,
                controllers: fieldControllers,
                onSave: _onSave,
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}

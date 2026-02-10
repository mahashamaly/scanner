import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../services/gemini_service.dart';

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

  // الصورة المختارة
  File? selectedImage;
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
        selectedSubCategory == null) return;

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
        selectedImage = File(pickedFile.path);
        isProcessing = true;
      });

      // تحليل الصورة تلقائياً
      await _analyzeImageAndPopulateFields();
    }
  }

  /// البحث عن أقرب تطابق في قائمة
  String? _findBestMatch(String searchTerm, List<String> options) {
    if (searchTerm.isEmpty || options.isEmpty) return null;
    
    // البحث عن تطابق دقيق أولاً
    if (options.contains(searchTerm)) return searchTerm;
    
    // البحث عن تطابق جزئي
    for (var option in options) {
      if (option.contains(searchTerm) || searchTerm.contains(option)) {
        debugPrint("🔍 تم العثور على تطابق: '$searchTerm' ≈ '$option'");
        return option;
      }
    }
    
    // البحث عن تطابق بعد إزالة "ال" التعريف
    final cleanSearch = searchTerm.replaceAll('ال', '').trim();
    for (var option in options) {
      final cleanOption = option.replaceAll('ال', '').trim();
      if (cleanOption.contains(cleanSearch) || cleanSearch.contains(cleanOption)) {
        debugPrint("🔍 تم العثور على تطابق بعد التنظيف: '$searchTerm' ≈ '$option'");
        return option;
      }
    }
    
    return null;
  }

  /// تحليل الصورة وتحديد التصنيفات والحقول تلقائياً
  Future<void> _analyzeImageAndPopulateFields() async {
    if (selectedImage == null) return;

    try {
      final geminiService = GeminiService();
      
      // استخراج البيانات الأولية من الصورة
      final extractedData = await geminiService.processDocument(selectedImage!.path);
      
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
                if (fieldControllers.containsKey(entry.key)) {
                  fieldControllers[entry.key]!.text = entry.value.toString();
                  debugPrint("✏️ تم ملء الحقل '${entry.key}' بالقيمة '${entry.value}'");
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

  /// معالجة الصورة وملء الحقول (تم الاستغناء عنها - الآن يتم التحليل تلقائياً)
  Future<void> _processImage() async {
    // هذه الدالة لم تعد مستخدمة
    // التحليل يتم تلقائياً في _analyzeImageAndPopulateFields
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
            // قسم اختيار الصورة (أولاً)
            _buildImageSection(),
            const SizedBox(height: 32),

            // قسم التصنيفات (يظهر بعد تحليل الصورة)
            if (selectedMainCategory != null) ...[
              _buildCategorySection(),
              const SizedBox(height: 32),
            ],

            // قسم الحقول الديناميكية (يظهر بعد تحديد التصنيفات)
            if (dynamicFields.isNotEmpty) ...[
              _buildDynamicFieldsSection(),
              const SizedBox(height: 32),
            ],

            // زر الحفظ
            if (dynamicFields.isNotEmpty) _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  /// قسم اختيار التصنيفات
  Widget _buildCategorySection() {
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
            onChanged: _onMainCategoryChanged,
          ),
          const SizedBox(height: 16),

          // التصنيف الفرعي
          if (subCategories.isNotEmpty)
            _buildDropdown(
              label: 'التصنيف الفرعي',
              value: selectedSubCategory,
              items: subCategories,
              onChanged: _onSubCategoryChanged,
            ),
          const SizedBox(height: 16),

          // تصنيف الملف
          if (fileClassifications.isNotEmpty)
            _buildDropdown(
              label: 'تصنيف الملف',
              value: selectedFileClassification,
              items: fileClassifications,
              onChanged: _onFileClassificationChanged,
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

  /// قسم اختيار الصورة
  Widget _buildImageSection() {
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
                'ابدأ بتصوير أو اختيار المستند',
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
            'سيتم تحليل المستند تلقائياً وملء الحقول',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // عرض الصورة المختارة
          if (selectedImage != null)
            Container(
              height: 250,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEB1555), width: 2),
                image: DecorationImage(
                  image: FileImage(selectedImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // أزرار اختيار الصورة
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 24),
                  label: Text(
                    'الكاميرا',
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
                  onPressed: isProcessing
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 24),
                  label: Text(
                    'المعرض',
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

          // مؤشر التحميل
          if (isProcessing)
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
                    '🤖 جاري تحليل المستند بالذكاء الاصطناعي...',
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

  /// قسم الحقول الديناميكية
  Widget _buildDynamicFieldsSection() {
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
            '📝 بيانات المستند',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // عرض الحقول الديناميكية
          ...dynamicFields.map((field) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildDynamicField(field),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// بناء حقل ديناميكي
  Widget _buildDynamicField(DynamicField field) {
    if (field.type == 'dropdown' && field.options != null) {
      return _buildDynamicDropdown(field);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              field.label,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (field.required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: fieldControllers[field.id],
          style: GoogleFonts.cairo(color: Colors.white),
          keyboardType: field.type == 'date'
              ? TextInputType.datetime
              : TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF111328),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEB1555), width: 2),
            ),
            hintText: 'أدخل ${field.label}',
            hintStyle: GoogleFonts.cairo(color: Colors.white38),
          ),
        ),
      ],
    );
  }

  /// بناء قائمة منسدلة ديناميكية
  Widget _buildDynamicDropdown(DynamicField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              field.label,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (field.required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
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
              value: fieldControllers[field.id]!.text.isEmpty
                  ? null
                  : fieldControllers[field.id]!.text,
              isExpanded: true,
              dropdownColor: const Color(0xFF111328),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              hint: Text(
                'اختر ${field.label}',
                style: GoogleFonts.cairo(color: Colors.white38),
              ),
              items: field.options!.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(
                    option,
                    style: GoogleFonts.cairo(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  fieldControllers[field.id]!.text = value ?? '';
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  /// زر الحفظ
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () {
        // هنا يمكن إضافة منطق الحفظ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💾 تم حفظ البيانات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEB1555),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        '💾 حفظ البيانات',
        style: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

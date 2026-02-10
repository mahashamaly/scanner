import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  // 🔑 هذا هو مفتاحك الجديد
  final String _apiKey = 'AIzaSyDtGvqTUWMnC97CezIqh_TLlMjDLf0lheY';

  Future<Map<String, dynamic>> processDocument(String imagePath) async {
    try {
      debugPrint("📡 محاولة استخراج شاملة باستخدام الموديل: gemini-1.5-flash");

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
        ],
      );
//قراءة الصورة
      final imageBytes = await File(imagePath).readAsBytes();
      
      final prompt = [
        Content.text("""
        أنت نظام ذكاء اصطناعي متخصص في تحليل صور المستندات الرسمية وأنظمة الأرشفة الحكومية.

مهمتك:
تحليل صورة المستند المرفقة واستخراج بياناتها وتصنيفها بدقة ضمن نظام أرشفة يحتوي على 9 تصنيفات رئيسية، مع تصنيفات فرعية وتصنيفات ملفات وحقول ديناميكية.

يوجد توافق تام بين التصنيفات والحقول المطلوبة وبين البيانات المستخرجة.

يجب أن يكون الإخراج بصيغة JSON فقط، بدون أي شرح أو نص إضافي.

================================
التصنيفات الرئيسية (mainCategory):
- كشوفات ومراسلات وكتب
- التقييم
- العقوبات
- الملف الصحي
- القرارات والأوامر الإدارية
- السيرة الذاتية
- إجراءات التوظيف
- الشهادات العلمية
- الأوراق الثبوتية والشخصية

================================
قواعد عامة:
1. اختر mainCategory الأنسب حسب محتوى المستند.
2. اختر subCategory ثم fileClass بناءً على القواعد أدناه.
3. استخرج فقط الحقول المرتبطة بالتصنيف المختار.
4. استخدم المفاتيح الإنجليزية (snake_case) لتتوافق مع النظام.
5. إذا لم توجد قيمة لحقل، اكتب "غير متوفر".
6. التواريخ بصيغة YYYY/MM/DD إن أمكن.
7. لا تختر قيم من خارج القوائم المحددة.

================================
1️⃣ كشوفات ومراسلات وكتب
subCategory: ثابت
fileClass:
- مراسلات داخلية → fields: correspondence_date, correspondence_title, correspondence_number
- مراسلات خارجية → fields: correspondence_date, correspondence_title, correspondence_number
- كتاب → fields: book_date, book_number, book_title
- كشف → fields: statement_title, statement_number, statement_date

================================
2️⃣ التقييم
subCategory:
- كتاب شكر وتقدير
- تقييم سنوي
fileClass: نفس subCategory

================================
3️⃣التصنيف الرئيسي: العقوبات
التصنيف الفرعي: نوع العقوبة
الحقل الثالث (fileClass) والحقول المرتبطة:

- تنبيه
  fields: penaltyDate, jobTitle, penaltyReason, penaltyNumber, penaltyDuration

- لفت نظر
  fields: penaltyDate, jobTitle, penaltyReason, penaltyNumber, penaltyDuration

- إنذار بالفصل
  fields: penaltyDate, jobTitle, penaltyReason, penaltyNumber, penaltyDuration

- إنذار نهائي بالفصل
  fields: penaltyDate, jobTitle, penaltyReason, penaltyNumber, penaltyDuration

- الحرمان من العلاوة الدورية
  fields: penaltyDate, jobTitle, penaltyReason, penaltyNumber, penaltyDuration

- الحرمان من الترقية
  fields: penaltyDate, jobTitle, penaltyReason, penaltyNumber, penaltyDuration

- تخفيض الدرجة
  fields: penaltyDate, jobTitle, penaltyReason, penaltyNumber, penaltyDuration

- خصم أيام بدون راتب
  fields: penaltyDate, jobTitle, penaltyReason, penaltyNumber, penaltyDuration

- الوقوف عن العمل لمدة لا تتجاوز 6 أشهر
  fields: penaltyDate, jobTitle, penaltyReason, penaltyNumber, penaltyDuration

- الإحالة إلى المعاش
  fields: penaltyDate, jobTitle, penaltyReason, penaltyNumber, penaltyDuration, retirementDate

- إنهاء خدمة بسبب التغيب
  fields: penaltyDate, jobTitle, penaltyReason, penaltyNumber, penaltyDuration, terminationDueToAbsenceDate

- الفصل عن الخدمة
  fields: penaltyDate, jobTitle, penaltyReason, terminationDate

================================
4️⃣ الملف الصحي
subCategory:
- إصابة عمل
- قرار لجنة طبية
fileClass:
- إصابة عمل → تقرير تأمين صحي، تقرير طبي، إصابة عمل
- قرار لجنة طبية → قرار لجنة طبية

================================
5️⃣ القرارات والأوامر الإدارية
subCategory:
- قرارات اللجان
- أمر إداري
- قرار رئيس البلدية

قرارات اللجان → fileClass:
- مكاتبات → document_title, document_date, entity
- قرارات → decision_title, decision_number, decision_date, decision_year,
job_title, department, section, grade_allowance
- لجنة مؤقتة → committee_formation_number, decision_year, committee_tasks,
committee_date, committee_title, membership_type

أمر إداري → fileClass:
- أمر إداري
- تكليف موظف
- إنهاء انتداب موظف
- انتداب
- نقل موظف
- نقل متقاعد

fields حسب النوع وتشمل:
order_number, order_year, job_title, department, section, unit, 
order_title, assignment_start_date, assignment_end_date, work_start_date

================================
6️⃣ السيرة الذاتية
subCategory:
سيرة ذاتية، عقد عمل، شهادة عضوية، شهادة خبرة،
شهادة تدريب، شهادة مدرب

سيرة ذاتية → كشوفات / سيرة ذاتية
fields: document_title, document_date

عقد عمل → fields:
job_title, contract_end_date, specialization, institution, document_date

شهادة عضوية → membership_number, union_name

شهادة خبرة → job_title, work_start_date, institution_name,
work_field, work_end_date

شهادة تدريب → training_institution, course_hours, course_specialization, 
course_type, course_name, course_date, accreditation_type

شهادة مدرب → course_name, course_date

================================
7️⃣ إجراءات التوظيف
subCategory:
- عملية التثبيت
- عملية التعاقد

عملية التثبيت → fileClass:
تثبيت موظفين، توصية بشأن مستخدم في الخدمة ببلدية غزة، أوراق ما قبل التثبيت
fields: document_date

عملية التعاقد → fileClass:
عقد العمل → contract_type, salary, contract_start_date, contract_end_date
توصيات لجنة المقابلة للعمل → document_date
نتائج المقابلات → minutes_date, job_title, percentage, ranking
نتائج امتحان المتقدمين → document_date
قرار → decision_date
إعلان وظيفة → announcement_type, announcement_end_date, department,
announcement_date, job_title

================================
8️⃣ الشهادات العلمية
subCategory:
- شهادة توجيهي
- شهادة جامعية

شهادة توجيهي → fields:
certificate_date, average, city, country, graduation_year,
branch, has_high_certification

شهادة جامعية → fields:
qualification, university_name, degree,
graduation_year, major, country, city,
grade, minor

================================
9️⃣ الأوراق الثبوتية والشخصية
subCategory:
- عائلي
- شخصي

عائلي → fileClass:
شهادة وفاة → death_date, deceased_id, relationship
تعديل حالة اجتماعية → id_number, relationship, date, name
شهادة قيد جامعة → document_date, child_id, child_name,
university_name, academic_year, country
شهادات ميلاد الأبناء → child_id, relationship, child_birth_date

شخصي → fileClass:
عقد الإيجار → tenant_name, city, neighborhood, contract_type,
rental_period, rental_start_date, rental_end_date,
building_number, street_number, rental_amount

جواز سفر → employee_id, passport_number
فاتورة مياه → account_number, subscriber_name, beneficiary_name,
street_number, building_number, unit_number
إقرار تغيير عنوان السكن → governorate, neighborhood, street_name,
building_number, street_number, nearest_landmark
عنوان السكن → city, neighborhood, street_name,
building_number, street_number, nearest_landmark
أمر بالإفراج → document_date, release_date, detention_period
شهادة حسن سير وسلوك → issue_date
شهادة عدم محكومية → issue_date, expiry_date
شهادة طلاق → wife_name, wife_id, divorce_date
بيانات البنك → account_number, bank_name, iban
رخصة قيادة → license_number, issue_date, expiry_date
بطاقة عضوية نقابة → union_name, membership_number, issue_date
عقد زواج → wife_name, wife_id, marriage_date,
husband_id, husband_name, relationship
شهادة ميلاد → document_date
صورة الهوية → employee_id, employee_full_name,
wife_full_name, wife_id, children_count,
id_issue_date

================================
إخراج JSON فقط بالشكل التالي:
{
  "mainCategory": "",
  "subCategory": "",
  "fileClass": "",
  "fields": {
    "field_id": "value"
  }
}

        """),
        Content.data('image/jpeg', imageBytes),
      ];
//ارسال طلب النموذج
      final response = await model.generateContent(prompt);
      final responseText = response.text;
      
      debugPrint("📄 Raw AI Response: $responseText");
//التأكد من وجود جسون فى النص
      if (responseText != null && responseText.contains('{')) {
        int start = responseText.indexOf('{');
        int end = responseText.lastIndexOf('}') + 1;
        String jsonString = responseText.substring(start, end);
        
        final Map<String, dynamic> data = jsonDecode(jsonString);

        return {
          'mainCategory': data['mainCategory']?.toString() ?? '',
          'subCategory': data['subCategory']?.toString() ?? '',
          'fileClass': data['fileClass']?.toString() ?? '',
          'fields': data['fields'] ?? {},
        };
      }
      
      throw Exception("لم يتم العثور على بيانات JSON في استجابة الذكاء الاصطناعي.");
    } catch (e) {
      debugPrint("⛔ GeminiService Error: $e");
      rethrow; // نترك الواجهة تتعامل مع الخطأ لإظهار السناك بار الصحيح
    }
  }

  /// معالجة المستند مع حقول ديناميكية
  Future<Map<String, String>> processDocumentWithFields(
    String imagePath,
    List<dynamic> fields,
  ) async {
    try {
      debugPrint("📡 استخراج بيانات ديناميكية باستخدام: gemini-1.5-flash");

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
        ],
      );

      final imageBytes = await File(imagePath).readAsBytes();

      // بناء قائمة الحقول المطلوبة
      final fieldDescriptions = fields.map((field) {
        return '- ${field.id}: ${field.label} (نوع: ${field.type})';
      }).join('\n');

      final prompt = [
        Content.text("""
          حلل هذه الصورة واستخرج البيانات التالية فقط:
          
          $fieldDescriptions

          قواعد مهمة:
          1. أرجع JSON فقط بدون أي نص إضافي.
          2. استخدم المفاتيح الإنجليزية المذكورة أعلاه (id).
          3. إذا لم تجد قيمة لحقل معين، اكتب "غير متوفر".
          4. للتواريخ، استخدم صيغة YYYY/MM/DD إن أمكن.
          5. كن دقيقاً في استخراج البيانات من الصورة.
        """),
        Content.data('image/jpeg', imageBytes),
      ];

      final response = await model.generateContent(prompt);
      final responseText = response.text;

      debugPrint("📄 AI Response: $responseText");

      if (responseText != null && responseText.contains('{')) {
        int start = responseText.indexOf('{');
        int end = responseText.lastIndexOf('}') + 1;
        String jsonString = responseText.substring(start, end);

        final Map<String, dynamic> data = jsonDecode(jsonString);

        // تحويل البيانات إلى Map<String, String>
        Map<String, String> result = {};
        for (var field in fields) {
          final fieldId = field.id;
          result[fieldId] = data[fieldId]?.toString() ?? 'غير متوفر';
        }

        return result;
      }

      throw Exception("لم يتم العثور على JSON في الاستجابة");
    } catch (e) {
      debugPrint("⛔ خطأ في معالجة المستند: $e");
      rethrow;
    }
  }
}

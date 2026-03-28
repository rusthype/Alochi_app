import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../../shared/constants/colors.dart';
import '../../../core/api/api_client.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  File? _file;
  String? _fileName;
  bool _analyzing = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile =
        await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      setState(() {
        _file = File(xfile.path);
        _fileName = xfile.name;
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _file = File(result.files.single.path!);
        _fileName = result.files.single.name;
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _analyze() async {
    if (_file == null) return;
    setState(() {
      _analyzing = true;
      _error = null;
    });
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(_file!.path,
            filename: _fileName),
      });
      final response = await ApiClient.instance.dio
          .post('/ai/homework/analyze/', data: formData);
      setState(() {
        _result = response.data as Map<String, dynamic>;
      });
    } catch (e) {
      setState(() => _error = 'Tahlil qilishda xatolik: $e');
    } finally {
      setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgMain,
      appBar: AppBar(title: const Text('Uy vazifasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Uy vazifasini yuklang',
                style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Rasm yoki PDF formatida',
                style: TextStyle(color: kTextSecondary)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: kBgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _file != null ? kOrange : kBgBorder,
                    width: _file != null ? 2 : 1,
                  ),
                ),
                child: _file != null
                    ? Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Icon(
                              Icons.check_circle_rounded,
                              color: kGreen,
                              size: 40),
                          const SizedBox(height: 8),
                          Text(_fileName ?? 'Fayl',
                              style: const TextStyle(
                                  color: kTextPrimary),
                              textAlign: TextAlign.center),
                          TextButton(
                            onPressed: () => setState(() {
                              _file = null;
                              _fileName = null;
                            }),
                            child: const Text("O'zgartirish",
                                style: TextStyle(
                                    color: kTextMuted)),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              color: kTextMuted, size: 48),
                          SizedBox(height: 8),
                          Text('Bosing yoki faylni suring',
                              style: TextStyle(
                                  color: kTextSecondary)),
                          Text('JPG, PNG, PDF',
                              style: TextStyle(
                                  color: kTextMuted,
                                  fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_rounded),
                    label: const Text('Rasm'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kTextSecondary,
                      side: const BorderSide(color: kBgBorder),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(
                        Icons.picture_as_pdf_rounded),
                    label: const Text('PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kTextSecondary,
                      side: const BorderSide(color: kBgBorder),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_file == null || _analyzing)
                    ? null
                    : _analyze,
                icon: _analyzing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(_analyzing
                    ? 'Tahlil qilinmoqda...'
                    : 'Tahlil qilish'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: kRed.withValues(alpha: 0.3)),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: kRed)),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              _ResultCard(data: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ResultCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final score = data['score'] ?? 0;
    final feedback =
        data['feedback'] as String? ?? data['message'] as String? ?? '';
    final color = scoreColor(score as num);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: kOrange),
              const SizedBox(width: 8),
              const Text('AI Tahlil natijasi',
                  style: TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$score%',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(feedback,
              style: const TextStyle(
                  color: kTextSecondary, height: 1.6)),
        ],
      ),
    );
  }
}

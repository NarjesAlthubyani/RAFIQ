import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  // ✅ تنسيق الاسم: nassif_house -> Nassif House
  String _formatLandmarkName(String raw) {
    if (raw.trim().isEmpty) return "";
    final words = raw.replaceAll("_", " ").split(" ");
    return words.map((w) {
      if (w.isEmpty) return "";
      return w[0].toUpperCase() + w.substring(1);
    }).join(" ");
  }

  Future<void> _pickFromGallery() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (img != null) {
      setState(() {
        _pickedImage = img;
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.camera);
    if (!mounted) return;
    if (img != null) {
      setState(() {
        _pickedImage = img;
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _submitToBackend() async {
    if (_pickedImage == null) return;

    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });

    try {
      // ✅ للـ Android Emulator 
      final uri = Uri.parse('http://10.0.2.2:8000/api/landmarks/recognize');

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('image', _pickedImage!.path),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode != 200) {
        setState(() {
          _error = 'Server error: ${streamedResponse.statusCode}\n$responseBody';
        });
        return;
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      setState(() {
        _result = data;
      });
    } catch (e) {
      setState(() {
        _error = 'Request failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPickOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFromCamera();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            Text(
              'Upload Photo',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
                fontFamily: 'Georgia',
              ),
            ),

            const SizedBox(height: 30),

            InkWell(
              onTap: _showPickOptions,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: DashedBorderPainter(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _pickedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud,
                                    size: 80,
                                    color: AppColors.accent.withOpacity(0.75),
                                  ),
                                  const Icon(
                                    Icons.arrow_upward,
                                    size: 30,
                                    color: AppColors.white,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Click to upload',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'PNG, PDF, AND JPEG',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.greyDark,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          )
                        : Image.file(
                            File(_pickedImage!.path),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
            ),

            // ================= RESULT =================
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            if (_result != null)
              Builder(builder: (context) {
                final recognized = (_result!["recognized"] == true);

                final rawName = (_result!["landmark_name"] ?? "").toString();
                final prettyName = _formatLandmarkName(rawName);

                final description =
                    (_result!["description"] ?? "").toString().trim();

                final confidence = _result!["confidence"];

                // تحويل confidence إلى نسبة مئوية
                String confidenceText = "";
                if (confidence != null) {
                  final c = (confidence is num)
                      ? confidence.toDouble()
                      : double.tryParse(confidence.toString());
                  if (c != null) {
                    confidenceText = "${(c * 100).toStringAsFixed(1)}%";
                  }
                }

                if (!recognized) {
                  final errorMsg = (_result!["error"] ??
                          "Unable to Recognize Landmark")
                      .toString();

                  return Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8)
                      ],
                    ),
                    child: Text(
                      errorMsg,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  );
                }

                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prettyName.isEmpty ? rawName : prettyName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        description.isEmpty
                            ? "No description available."
                            : description,
                      ),

                      const SizedBox(height: 8),

                      if (confidenceText.isNotEmpty)
                        Text("Confidence: $confidenceText"),
                    ],
                  ),
                );
              }),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _pickedImage = null;
                        _result = null;
                        _error = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                          color: AppColors.primary.withOpacity(0.35)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.greyDark,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_pickedImage == null || _isLoading)
                        ? null
                        : _submitToBackend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.primary.withOpacity(0.55)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const double dashWidth = 5;
    const double dashSpace = 3;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
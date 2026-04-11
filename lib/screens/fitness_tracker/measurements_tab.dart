import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../models/fitness_week.dart';
import '../../providers/fitness_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/app_theme.dart';

class MeasurementsTab extends StatefulWidget {
  final FitnessWeek week;

  const MeasurementsTab({super.key, required this.week});

  @override
  State<MeasurementsTab> createState() => _MeasurementsTabState();
}

class _MeasurementsTabState extends State<MeasurementsTab> {
  final _chestCtrl = TextEditingController();
  final _calvesCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _glutesCtrl = TextEditingController();
  final _armCtrl = TextEditingController();
  final _thighCtrl = TextEditingController();
  String? _frontPhotoPath;
  String? _backPhotoPath;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final m = context.read<FitnessProvider>().measurement;
      if (m != null) {
        _chestCtrl.text = m.chest.toStringAsFixed(1);
        _calvesCtrl.text = m.calves.toStringAsFixed(1);
        _waistCtrl.text = m.waist.toStringAsFixed(1);
        _glutesCtrl.text = m.glutes.toStringAsFixed(1);
        _armCtrl.text = m.arm.toStringAsFixed(1);
        _thighCtrl.text = m.thigh.toStringAsFixed(1);
        _frontPhotoPath = m.frontPhotoPath;
        _backPhotoPath = m.backPhotoPath;
      }
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _chestCtrl.dispose();
    _calvesCtrl.dispose();
    _waistCtrl.dispose();
    _glutesCtrl.dispose();
    _armCtrl.dispose();
    _thighCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l.bodyMeasurements,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        _buildMeasurementField(_chestCtrl, l.chestCm),
        _buildMeasurementField(_calvesCtrl, l.calvesCm),
        _buildMeasurementField(_waistCtrl, l.waistCm),
        _buildMeasurementField(_glutesCtrl, l.glutesCm),
        _buildMeasurementField(_armCtrl, l.armCm),
        _buildMeasurementField(_thighCtrl, l.thighCm),
        const SizedBox(height: 24),
        Text(
          l.photos,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPhotoCard(l.front, _frontPhotoPath, isfront: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildPhotoCard(l.back, _backPhotoPath, isfront: false)),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saveMeasurements,
          icon: const Icon(Icons.save_rounded),
          label: Text(l.saveMeasurements),
        ),
      ],
    ),
    );
  }

  Widget _buildMeasurementField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _buildPhotoCard(String label, String? photoPath, {required bool isfront}) {
    return GestureDetector(
      onTap: () => _pickPhoto(isfront),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: photoPath != null && File(photoPath).existsSync()
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(photoPath), fit: BoxFit.cover),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_rounded, size: 36, color: AppColors.textTertiary),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
      ),
    );
  }

  Future<void> _pickPhoto(bool isFront) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (image == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(appDir.path, 'body_photos'));
    if (!photosDir.existsSync()) {
      photosDir.createSync(recursive: true);
    }

    final fileName = '${widget.week.id}_${isFront ? 'front' : 'back'}.jpg';
    final savedPath = p.join(photosDir.path, fileName);
    await File(image.path).copy(savedPath);

    setState(() {
      if (isFront) {
        _frontPhotoPath = savedPath;
      } else {
        _backPhotoPath = savedPath;
      }
    });
  }

  void _saveMeasurements() {
    context.read<FitnessProvider>().saveMeasurement(
      weekId: widget.week.id,
      chest: double.tryParse(_chestCtrl.text) ?? 0,
      calves: double.tryParse(_calvesCtrl.text) ?? 0,
      waist: double.tryParse(_waistCtrl.text) ?? 0,
      glutes: double.tryParse(_glutesCtrl.text) ?? 0,
      arm: double.tryParse(_armCtrl.text) ?? 0,
      thigh: double.tryParse(_thighCtrl.text) ?? 0,
      frontPhotoPath: _frontPhotoPath,
      backPhotoPath: _backPhotoPath,
    );

    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.measurementsSaved), duration: const Duration(seconds: 2)),
    );
  }
}

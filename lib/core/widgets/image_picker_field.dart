import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Reusable photo chooser for the Create Safety Report and Create Community Post
/// forms. Works on Android, iOS and Flutter web (it uses bytes, never dart:io).
///
///   XFile? _image;
///   ImagePickerField(onChanged: (file) => _image = file)
class ImagePickerField extends StatefulWidget {
  const ImagePickerField({super.key, required this.onChanged, this.label = 'Add photo'});

  final ValueChanged<XFile?> onChanged;
  final String label;

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _bytes;
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _bytes = bytes);
      widget.onChanged(file);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load that photo. Please try another.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clear() {
    setState(() => _bytes = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(_bytes!, height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
          IconButton.filled(
            tooltip: 'Remove photo',
            onPressed: _clear,
            icon: const Icon(Icons.close),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _busy ? null : () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(widget.label),
          ),
        ),
        if (!kIsWeb) ...[
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Camera'),
            ),
          ),
        ],
      ],
    );
  }
}

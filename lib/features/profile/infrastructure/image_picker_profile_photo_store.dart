import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../domain/profile_photo_store.dart';

/// `image_picker` + the app documents folder. The gallery uses the
/// system photo picker and the camera uses the system camera app, so
/// neither needs a runtime permission from GuiaGo.
class ImagePickerProfilePhotoStore implements ProfilePhotoStore {
  ImagePickerProfilePhotoStore({
    ImagePicker? picker,
    Future<Directory> Function()? directory,
  })  : _picker = picker ?? ImagePicker(),
        _directory = directory ?? getApplicationDocumentsDirectory;

  final ImagePicker _picker;
  final Future<Directory> Function() _directory;

  @override
  Future<Result<String?>> pick(ProfilePhotoSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: switch (source) {
          ProfilePhotoSource.camera => ImageSource.camera,
          ProfilePhotoSource.gallery => ImageSource.gallery,
        },
        maxWidth: 768,
        maxHeight: 768,
        imageQuality: 85,
      );
      if (picked == null) return const Success<String?>(null);
      final Directory dir = await _directory();
      // A new name every time, so the image cache never shows the old one.
      final String destination = p.join(
        dir.path,
        'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await picked.saveTo(destination);
      return Success<String?>(destination);
    } on Exception catch (error) {
      return Fail<String?>(
        PlatformFailure('Could not get a profile photo', cause: error),
      );
    }
  }

  @override
  Future<void> delete(String path) async {
    try {
      final File file = File(path);
      if (file.existsSync()) await file.delete();
    } on Exception {
      // A leftover file is harmless; nothing to recover.
    }
  }
}

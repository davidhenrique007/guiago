import '../../../core/result/result.dart';

/// Where a new profile photo comes from.
enum ProfilePhotoSource { camera, gallery }

/// Gets a profile photo from the user and keeps a copy of it inside the
/// app, so it survives the original being moved or deleted.
abstract interface class ProfilePhotoStore {
  /// Asks the user for a photo. `Success(null)` means the user cancelled;
  /// `Success(path)` is the path of the app's own copy.
  Future<Result<String?>> pick(ProfilePhotoSource source);

  /// Deletes an app-owned copy. Never throws; a missing file is fine.
  Future<void> delete(String path);
}

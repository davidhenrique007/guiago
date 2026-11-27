import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/profile_photo_store.dart';
import '../infrastructure/image_picker_profile_photo_store.dart';

final Provider<ProfilePhotoStore> profilePhotoStoreProvider =
    Provider<ProfilePhotoStore>((ref) => ImagePickerProfilePhotoStore());

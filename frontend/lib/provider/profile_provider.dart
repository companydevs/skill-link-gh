import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_link_gh/notifier/profile_notifier.dart';

// Profile Notifier Provider
final profileNotifierProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  () {
    return ProfileNotifier();
  },
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:skill_link_gh/data/repository/booking_repository.dart';
import 'package:skill_link_gh/notifier/booking_notifier.dart';

final bookingRepositoryProvider = Provider((ref) => BookingRepository());

final bookingNotifierProvider =
    StateNotifierProvider<BookingNotifier, BookingState>((ref) {
      final repository = ref.watch(bookingRepositoryProvider);
      return BookingNotifier(repository);
    });

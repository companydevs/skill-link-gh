import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_link_gh/notifier/wallet_notifier.dart';

final walletNotifierProvider = NotifierProvider<WalletNotifier, WalletState>(
  WalletNotifier.new,
);

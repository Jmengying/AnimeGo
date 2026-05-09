import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_auth_service.dart';

final authServiceProvider = Provider<LocalAuthService>((ref) {
  final service = LocalAuthService();
  service.init();
  return service;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).isLoggedIn;
});

final currentUserProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});

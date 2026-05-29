import 'dart:math';

class InviteEngine {
  /// Generates a clean, unambiguous 6-character uppercase alphanumeric string
  static String generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }
}
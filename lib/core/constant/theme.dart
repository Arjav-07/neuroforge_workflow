import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgeTheme {
  // Light Aesthetic Color Palette from Screenshot
  static const Color background = Color(0xFFF2F1ED); // Soft off-white
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color brandBlue = Color(0xFF304CB1);   // Vibrant royal blue
  static const Color textDark = Color(0xFF0F172A);    // Rich slate dark text
  static const Color textMuted = Color(0xFF64748B);   // Soft gray for body text
  static const Color dotInactive = Color(0xFFCBD5E1); // Inactive slide dot
  static const Color divider = Color(0xFFBDBDBD);     // Divider color

  // Typography
  static TextStyle displayHeader = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: textDark,
    height: 1.1, 
  );

  static TextStyle bodyText = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textMuted,
    height: 1.4,
  );

  static TextStyle actionButtonText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: surfaceWhite,
  );
}

Widget buildCustomInputField({
  required TextEditingController controller,
  required String hintText, 
  required IconData icon, 
  bool isObscure = false,
  Widget? suffixIcon,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    height: 52,
    decoration: BoxDecoration(
      color: kInputFieldBg,
      borderRadius: BorderRadius.circular(40),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Vertically centers Row content
      children: [
        // Icon Circle Wrapper
        Container(
          width: 32, // Marginally bumped for a better structural balance alongside a 52 height parent
          height: 32,
          alignment: Alignment.center, // Guarantees the icon sits dead center in the circle
          decoration: const BoxDecoration(
            color: kIconCircleBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: brandBlue, size: 16),
        ),
        const SizedBox(width: 14),
        
        // Input Field Wrapper
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            textAlignVertical: TextAlignVertical.center, // Aligns input cursor and typing text perfectly to center axis
            decoration: InputDecoration(
              suffixIcon: suffixIcon,
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.black54, fontSize: 14),
              border: InputBorder.none,
              isDense: true, 
              // Adds micro content margins to balance vertical alignment discrepancies across platforms
              contentPadding: const EdgeInsets.symmetric(vertical: 2), 
            ),
          ),
        ),
      ],
    ),
  );
}


// =========================================================================
// 🎨 THEME CONSTANTS & CONFIGURATION
// =========================================================================
const Color kBackgroundColor = Color(0xFFECECE8);
const Color brandBlue = Color(0xFF2649B7);
final Color kInputFieldBg = Colors.black.withOpacity(0.1);
const Color kMutedTextColor = Color(0xFF7A7A7A);
const Color kIconCircleBg = Color(0xFFD6D9E6);






Widget buildMainActionButton({
  required String label,
  required VoidCallback onTap,
}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandBlue,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// Widget buildSocialIconCircle(String emoji) {
//   return Container(
//     width: 42,
//     height: 42,
//     decoration: const BoxDecoration(color: kIconCircleBg, shape: BoxShape.circle),
//     alignment: Alignment.center,
//     child: Text(emoji, style: const TextStyle(fontSize: 18)),
//   );
// }



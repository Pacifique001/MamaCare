// lib/utils/text_styles.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:mama_care/utils/app_colors.dart';

class TextStyles {
  const TextStyles._();

  static final String _primaryFontFamily =
      GoogleFonts.poppins().fontFamily ?? 'Roboto';

  // --- Headline Styles ---
  static final TextStyle headline1 = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 24.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
  static final TextStyle headline2 = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  // --- Title Styles ---
  static final TextStyle title = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  static final TextStyle titleCard = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 15.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );
  static final TextStyle titleWhite = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  // ADDED: titleBold
  static final TextStyle titleBold = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  // --- Body Text Styles ---
  static final TextStyle body = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 13.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
    height: 1.5,
  );
  static final TextStyle bodyBold = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 13.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.5,
  );
  static final TextStyle bodyBlack = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 13.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
    height: 1.5,
  );
  static final TextStyle bodyGrey = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 13.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textGrey,
    height: 1.5,
  );
  static final TextStyle bodyWhite = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 13.sp,
    fontWeight: FontWeight.normal,
    color: Colors.white.withOpacity(0.9),
    height: 1.5,
  );
  static final TextStyle bodySmall = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textGrey,
    height: 1.4,
  );

  // --- Smaller Text Styles ---
  static final TextStyle small = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 11.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
  );
  static final TextStyle smallGrey = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 11.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textGrey,
  );
  static final TextStyle smallPrimary = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 11.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );
  // ADDED: smallBold
  static final TextStyle smallBold = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 11.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  // ADDED: smallBody (can be same as small or slightly different)
  static final TextStyle smallBody = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 11.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
    height: 1.4,
  );

  // --- Button and Link Styles ---
  static final TextStyle buttonText = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  static final TextStyle linkText = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 13.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
  // ADDED: buttonTextSmall
  static final TextStyle buttonTextSmall = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  ); // White for primary button example

  // --- Specific Styles Used ---
  static final TextStyle textFieldLabel = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );
  static final TextStyle errorText = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 11.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.error,
  );

  // --- List Item Styles ---
  static final TextStyle listTitle = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  static final TextStyle listSubtitle = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 11.5.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textGrey,
    height: 1.4,
  );

  // --- AppBar Title ---
  // Corrected: static final TextStyle appBarTitle; (This was likely the cause of the error if not initialized)
  // Provide an actual style definition
  static final TextStyle appBarTitle = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark, // Or Colors.white depending on AppBar theme
  );
}

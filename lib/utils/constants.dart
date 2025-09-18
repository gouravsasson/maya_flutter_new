// lib/utils/constants.dart
import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFF1976D2);
const Color kPrimaryDark = Color(0xFF0D47A1);
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kTextColor = Color(0xFF212121);
const Color kTextSecondary = Color(0xFF757575);
const Color kTextHint = Color(0xFF9E9E9E);
const Color kListeningBackground = Color(0xFFF3E5F5);
const Color kTranscriptBackground = Color(0xFFF1F8E9);

// ✅ New status colors
const Color kSuccessColor = Color(0xFF4CAF50); // green
const Color kWarningColor = Color(0xFFFFA000); // amber
const Color kErrorColor   = Color(0xFFD32F2F); // red

// ✅ Input background color
const Color kInputBackground = Color(0xFFF5F5F5);

// ✅ Text styles
const TextStyle kTitleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
);
const TextStyle kBodyStyle = TextStyle(fontSize: 14);

// ✅ Button style baseline (can be copied with .copyWith in widgets)
const TextStyle kButtonStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

const int kMaxLines = 2;
const int kMaxDisplayLength = 100; // ✅ max display characters

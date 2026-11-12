// lib/core/theme/app_theme.dart
//
// Tema único del Sistema OCS — Corporación Ramis

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================
// PALETA CORPORATIVA RAMIS
// ============================================

class AppTheme {
  AppTheme._();

  // Colores de marca
  static const Color primary = Color(0xFF193D8F);
  static const Color primaryDark = Color(0xFF0F1F45);
  static const Color primaryLight = Color(0xFFE3EEF8);
  static const Color secondary = Color(0xFF79B42A);
  static const Color secondaryDark = Color(0xFF426719);
  static const Color secondaryLight = Color(0xFFEEF6E3);
  static const Color accent = secondary;

  // Fondos y superficies
  static const Color background = Color(0xFFF5F6F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  // Texto
  static const Color textPrimary = Color(0xFF252A32);
  static const Color textSecondary = Color(0xFF626B76);
  static const Color textDisabled = Color(0xFF6B7480);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Estados
  static const Color success = Color(0xFF28734D);
  static const Color warning = Color(0xFF966000);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = primary;

  // UI
  static const Color border = Color(0xFFDDE2E8);
  static const Color divider = Color(0xFFE9ECF0);
  static const Color shadow = Color(0x1A000000);

  // Headers y componentes especiales
  static const Color statusHeaderDark = primaryDark;
  static const Color progressCircleBg = Color(0x1AFFFFFF);
  static const Color quantityBadgeBg = secondaryLight;
  static const Color quantityBadgeBorder = secondary;
  static const Color unitBadgeBg = Color(0x0D193D8F);

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient statusHeaderGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tabIndicatorGradient = LinearGradient(
    colors: [primary, secondary],
  );

  static const LinearGradient actionButtonGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, secondaryLight],
  );

  // Sombras
  static final BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 15,
    offset: const Offset(0, 4),
  );

  static final BoxShadow buttonShadow = BoxShadow(
    color: primary.withValues(alpha: 0.25),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );

  // Tipografía
  static const String fontFamily = 'Roboto';

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: 0,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: 0,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: 0,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: 0,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: 0,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: 0,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: 0,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: 0,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: 0,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: 0,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: 0,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: 0,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textDisabled,
  );

  // Bordes
  static const BorderRadius borderRadiusSmall =
      BorderRadius.all(Radius.circular(8));
  static const BorderRadius borderRadiusMedium =
      BorderRadius.all(Radius.circular(8));
  static const BorderRadius borderRadiusLarge =
      BorderRadius.all(Radius.circular(8));
  static const BorderRadius borderRadiusExtraLarge =
      BorderRadius.all(Radius.circular(12));
  static const BorderRadius borderRadiusCircle =
      BorderRadius.all(Radius.circular(100));

  static const BorderSide borderSide = BorderSide(color: border, width: 1);
  static const BorderSide borderSideThick = BorderSide(color: border, width: 2);

  // Espaciado
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;

  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;
  static const double iconSizeExtraLarge = 32.0;

  // Input decoration reutilizable
  static InputDecoration get inputDecoration => InputDecoration(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingL,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textDisabled, fontSize: 14),
        prefixIconColor: primary,
      );

  // Tabla
  static Color get tableRowOdd => secondary.withValues(alpha: 0.08);
  static Color get tableRowEven => primary.withValues(alpha: 0.06);

  // Helpers
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aprobado':
      case 'enviado':
      case 'completado':
        return success;
      case 'pendiente':
        return warning;
      case 'rechazado':
      case 'eliminado':
        return error;
      default:
        return info;
    }
  }

  static Color getProgressColor(double progress) {
    if (progress >= 100) return success;
    if (progress > 0) return primary;
    return textDisabled;
  }

  // ============================================
  // ThemeData central — usar en MaterialApp
  // ============================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: divider,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: textOnPrimary,
        secondary: secondary,
        onSecondary: primaryDark,
        primaryContainer: primaryLight,
        onPrimaryContainer: primaryDark,
        secondaryContainer: secondaryLight,
        onSecondaryContainer: secondaryDark,
        tertiary: primary,
        onTertiary: textOnPrimary,
        tertiaryContainer: primaryLight,
        onTertiaryContainer: primaryDark,
        surfaceTint: Colors.transparent,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onError: textOnPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 56,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: surface,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: surface,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0,
        ),
        iconTheme: IconThemeData(color: textSecondary, size: 22),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: surface,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 11,
              letterSpacing: 0,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: states.contains(WidgetState.selected)
                  ? primary
                  : textSecondary,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 22,
              color: states.contains(WidgetState.selected)
                  ? primary
                  : textSecondary,
            )),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: secondary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: textOnPrimary,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusSmall),
        extendedTextStyle: labelLarge.copyWith(color: textOnPrimary),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: borderRadiusSmall,
            side: const BorderSide(color: border)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        minLeadingWidth: 20,
        horizontalTitleGap: 12,
        minVerticalPadding: 8,
        titleTextStyle: titleSmall,
        subtitleTextStyle: bodySmall,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          iconSize: 20,
          foregroundColor: textSecondary,
        ),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryDark,
        contentTextStyle: bodyMedium.copyWith(color: textOnPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
      ),
      textTheme: const TextTheme(
        displayLarge: headlineLarge,
        displayMedium: headlineMedium,
        displaySmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: textOnPrimary,
        minimumSize: const Size(48, 48),
        textStyle: labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: borderRadiusSmall),
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          textStyle: labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXL,
            vertical: 10,
          ),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          textStyle: labelLarge,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXL,
            vertical: 12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: labelLarge,
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: bodyMedium.copyWith(color: textSecondary),
        hintStyle: bodyMedium.copyWith(color: textDisabled),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingL,
          vertical: 14,
        ),
        errorMaxLines: 2,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primaryLight,
        checkmarkColor: primary,
        labelStyle: labelMedium.copyWith(color: textPrimary),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: borderRadiusSmall),
      ),
      iconTheme: const IconThemeData(color: primary, size: iconSizeLarge),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: headlineSmall,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusExtraLarge),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      ),
    );
  }
}

// ============================================
// EXTENSIONES DE COLOR
// ============================================

extension ColorExtensions on Color {
  Color get lighten10 =>
      Color.alphaBlend(Colors.white.withValues(alpha: 0.1), this);
  Color get lighten20 =>
      Color.alphaBlend(Colors.white.withValues(alpha: 0.2), this);
  Color get darken10 =>
      Color.alphaBlend(Colors.black.withValues(alpha: 0.1), this);
  Color get darken20 =>
      Color.alphaBlend(Colors.black.withValues(alpha: 0.2), this);
}

// ============================================
// EXTENSIONES DE CONTEXTO
// ============================================

extension ThemeExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;

  Color get primaryColor => AppTheme.primary;
  Color get secondaryColor => AppTheme.secondary;
  Color get backgroundColor => AppTheme.background;
  Color get surfaceColor => AppTheme.surface;
  Color get textColor => AppTheme.textPrimary;
  Color get successColor => AppTheme.success;
  Color get warningColor => AppTheme.warning;
  Color get errorColor => AppTheme.error;

  TextStyle get headlineLarge => AppTheme.headlineLarge;
  TextStyle get headlineMedium => AppTheme.headlineMedium;
  TextStyle get titleMedium => AppTheme.titleMedium;
  TextStyle get bodyMedium => AppTheme.bodyMedium;
  TextStyle get bodySmall => AppTheme.bodySmall;

  double get spacingS => AppTheme.spacingS;
  double get spacingM => AppTheme.spacingM;
  double get spacingL => AppTheme.spacingL;
  double get spacingXL => AppTheme.spacingXL;

  BorderRadius get borderRadiusMedium => AppTheme.borderRadiusMedium;
  BorderRadius get borderRadiusLarge => AppTheme.borderRadiusLarge;
  BoxShadow get cardShadow => AppTheme.cardShadow;
}

// ============================================
// WIDGETS REUTILIZABLES
// ============================================

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final bool showShadow;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spacingL),
    this.backgroundColor,
    this.showShadow = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.card,
        borderRadius: borderRadius ?? AppTheme.borderRadiusLarge,
        boxShadow: showShadow ? [AppTheme.cardShadow] : null,
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isFullWidth;
  final bool isElevated;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isFullWidth = false,
    this.isElevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppTheme.primary,
        foregroundColor: textColor ?? AppTheme.textOnPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXL,
          vertical: AppTheme.spacingL,
        ),
        shape:
            RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
        elevation: isElevated ? 2 : 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppTheme.iconSizeMedium),
            const SizedBox(width: AppTheme.spacingS),
          ],
          Text(
            text,
            style: AppTheme.labelLarge.copyWith(
              color: textColor ?? AppTheme.textOnPrimary,
            ),
          ),
        ],
      ),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

class AppInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const AppInfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? AppTheme.primary,
              size: AppTheme.iconSizeSmall,
            ),
            const SizedBox(width: AppTheme.spacingS),
            Text(
              label,
              style:
                  AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class AppBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool isUpperCase;

  const AppBadge({
    super.key,
    required this.text,
    required this.color,
    this.isUpperCase = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppTheme.borderRadiusSmall,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isUpperCase ? text.toUpperCase() : text,
        style: AppTheme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AppProgressBar extends StatelessWidget {
  final double progress;
  final Color? color;
  final double height;

  const AppProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.height = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? AppTheme.getProgressColor(progress);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.border,
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: FractionallySizedBox(
        widthFactor: (progress / 100).clamp(0.0, 1.0),
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: progressColor,
            borderRadius: AppTheme.borderRadiusSmall,
          ),
        ),
      ),
    );
  }
}

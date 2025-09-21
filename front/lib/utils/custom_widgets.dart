import 'package:front/providers/obscure_text_provider.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomWidgets {
  static Widget customTextFormField({
    required TextEditingController controller,
    required String label,
    required Color borderColor,
    required Color textColor,
    required double fontsize,
    bool obscureText = false,
    bool disabled = false,
    int maxLine = 1,
    bool isnumber = false,
    String? Function(String?)? validator,
  }) {
    return ChangeNotifierProvider<ObscureTextProvider>(
      create: (_) => ObscureTextProvider(obscureText),
      child: Consumer<ObscureTextProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              keyboardType: isnumber
                  ? TextInputType.number
                  : TextInputType.text,
              controller: controller,
              obscureText: provider.obscureText,
              enabled: !disabled,
              maxLines: maxLine,

              decoration: customInputDecoration(
                label: label,
                borderColor: borderColor,
                provider: provider,
                obscureText: obscureText,
                disabled: disabled,
              ),
              style: TextStyle(fontSize: fontsize, color: textColor),
              validator: validator,
            ),
          );
        },
      ),
    );
  }

  static InputDecoration customInputDecoration({
    required String label,
    required Color borderColor,
    ObscureTextProvider? provider,
    required bool obscureText,
    bool disabled = false,
  }) {
    return InputDecoration(
      suffixIcon: obscureText
          ? IconButton(
              icon: Icon(
                provider!.obscureText ? Icons.visibility_off : Icons.visibility,
                color: AppColors.foregroundColor,
              ),
              onPressed: () {
                provider.toggle();
              },
            )
          : null,
      labelText: label,
      labelStyle: TextStyle(color: AppColors.foregroundColor),
      enabledBorder: _borderStyle(AppColors.foregroundColor),
      disabledBorder: _borderStyle(AppColors.disabledInputFillColor!),
      focusedBorder: _borderStyle(AppColors.primary),
      errorBorder: _borderStyle(AppColors.errorColor),
      focusedErrorBorder: _borderStyle(AppColors.primary),
      filled: disabled,
    );
  }

  static OutlineInputBorder _borderStyle(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
      borderSide: BorderSide(color: color),
    );
  }

  static ButtonStyle elevatedButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(
        vertical: AppSizes.getScreenHeight(context) * 0.02,
        horizontal: AppSizes.getScreenWidth(context) * 0.05,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    );
  }

  static TextStyle textStyle(BuildContext context) {
    return TextStyle(
      fontSize: AppSizes.inputFontSize(context),
      color: AppColors.titleColor,
    );
  }
}

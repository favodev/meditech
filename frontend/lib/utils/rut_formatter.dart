import 'package:flutter/services.dart';

/// Formateador de RUT chileno que convierte automáticamente
/// el input del usuario al formato: XX.XXX.XXX-X
///
/// El usuario solo ingresa números y el dígito verificador,
/// el formateador agrega puntos y guión automáticamente.
class RutFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Obtener solo los dígitos y letras (para la K)
    String text = newValue.text.toUpperCase().replaceAll(
      RegExp(r'[^0-9K]'),
      '',
    );

    // Limitar longitud (máximo 9 caracteres: 8 dígitos + 1 verificador)
    if (text.length > 9) {
      text = text.substring(0, 9);
    }

    // Si está vacío, retornar vacío
    if (text.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Formatear el RUT
    String formatted = _formatRut(text);

    // Calcular nueva posición del cursor
    int selectionIndex = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }

  String _formatRut(String text) {
    // Separar dígito verificador
    String digits = text.length > 1 ? text.substring(0, text.length - 1) : text;
    String verifier = text.length > 1 ? text.substring(text.length - 1) : '';

    // Formatear la parte numérica con puntos
    String formatted = '';
    int count = 0;

    // Recorrer dígitos de derecha a izquierda
    for (int i = digits.length - 1; i >= 0; i--) {
      if (count == 3) {
        formatted = '.$formatted';
        count = 0;
      }
      formatted = digits[i] + formatted;
      count++;
    }

    // Agregar guión y dígito verificador si existe
    if (verifier.isNotEmpty) {
      formatted = '$formatted-$verifier';
    }

    return formatted;
  }
}

/// Convierte un RUT formateado (con puntos y guión) a solo números
/// Ejemplo: "12.345.678-9" -> "123456789"
String cleanRut(String rut) {
  return rut.toUpperCase().replaceAll(RegExp(r'[^0-9K]'), '');
}

/// Formatea un RUT sin formato a formato chileno
/// Ejemplo: "123456789" -> "12.345.678-9"
String formatRut(String rut) {
  final cleaned = cleanRut(rut);
  if (cleaned.isEmpty) return '';

  final formatter = RutFormatter();
  final result = formatter.formatEditUpdate(
    const TextEditingValue(),
    TextEditingValue(text: cleaned),
  );

  return result.text;
}

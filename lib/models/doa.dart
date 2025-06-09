class Doa {
  final String id;
  final String title;
  final String arabicText;
  final String latinText;
  final String translation;
  final String source;

  Doa({
    required this.id,
    required this.title,
    this.arabicText = '',
    required this.latinText,
    required this.translation,
    this.source = '',
  });
}
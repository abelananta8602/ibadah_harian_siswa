class Hadith {
  final String id;
  final String title;
  final String arabicText;
  final String translation;
  final String narrator;
  final String category;

  Hadith({
    required this.id,
    required this.title,
    this.arabicText = '',
    required this.translation,
    this.narrator = '',
    this.category = '',
  });
}
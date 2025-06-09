class Juz {
  final int number;
  final String name;

  Juz({required this.number, required this.name});

  factory Juz.fromJson(Map<String, dynamic> json) {
    return Juz(
      number: json['juz'] ?? 0,
      name: "Juz ${json['juz'] ?? 0}",
    );
  }
}

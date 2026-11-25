/// Immutable adhkar domain models, independent of the database layer.
class AdhkarCategory {
  const AdhkarCategory({
    required this.id,
    required this.title,
    required this.featured,
    required this.itemCount,
    this.streakKey,
  });

  final String id;
  final String title;
  final bool featured;
  final int itemCount;
  final String? streakKey;

  bool get hasStreak => streakKey != null && streakKey!.isNotEmpty;
}

class AdhkarItem {
  const AdhkarItem({
    required this.id,
    required this.categoryId,
    required this.text,
    required this.repeatCount,
    required this.reference,
  });

  final String id;
  final String categoryId;
  final String text;
  final int repeatCount;
  final String reference;
}

/// Attribution carried by the bundled Hisn al-Muslim asset.
class AdhkarSource {
  const AdhkarSource({
    required this.title,
    required this.author,
    required this.repository,
    required this.license,
    required this.copyright,
  });

  final String title;
  final String author;
  final String repository;
  final String license;
  final String copyright;

  factory AdhkarSource.fromJson(Map<String, dynamic> json) => AdhkarSource(
        title: json['title'] as String,
        author: json['author'] as String,
        repository: json['repository'] as String,
        license: json['license'] as String,
        copyright: json['copyright'] as String,
      );
}

class Book {
  final int id;
  final String title;
  final String author;
  final int pageCount;
  final String genre;
  final String description;
  final double rating;
  final bool isAvailable;
  Book({required this.id, required this.title, required this.author, required this.isAvailable, required this.pageCount, required this.description, required this.genre, required this.rating});

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        id: j['id'],
        title: j['title'],
        author: j['author'],
        isAvailable: j['isAvailable'] ?? true,
        pageCount: j['pageCount'] ?? 0,
        description: j['description'] ?? '',
        genre: j['genre'] ?? '',
        rating: (j['rating'] != null)
            ? (j['rating'] as num).toDouble()
            : 0.0,
      );
}
class Book {
  final int id;
  final String title;
  final String author;
  final bool isAvailable;
  Book({required this.id, required this.title, required this.author, required this.isAvailable});
  factory Book.fromJson(Map<String, dynamic> j) => Book(
    id: j['id'],
    title: j['title'],
    author: j['author'],
    isAvailable: j['isAvailable'] ?? true,
  );
}
class BorrowRecord {
  final int id, bookId;
  final String title, author;
  final DateTime borrowedAt;
  final DateTime? returnedAt;

  BorrowRecord({
    required this.id,
    required this.bookId,
    required this.title,
    required this.author,
    required this.borrowedAt,
    this.returnedAt,
  });

factory BorrowRecord.fromJson(Map<String, dynamic> j) => BorrowRecord(
  id: (j['id']) ?? 0,         
  bookId: j['bookId'] ?? 0,  
  title: j['title'] as String? ?? '',
  author: j['author'] as String? ?? '',
  borrowedAt: DateTime.parse(j['borrowedAt'] as String),
  returnedAt: j['returnedAt'] == null
      ? null
      : DateTime.parse(j['returnedAt'] as String),
);
}
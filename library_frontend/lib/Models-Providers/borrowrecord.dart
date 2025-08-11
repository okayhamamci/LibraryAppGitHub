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
    id: j['id'],
    bookId: j['bookId'],
    title: j['title'],
    author: j['author'],
    borrowedAt: DateTime.parse(j['borrowedAt']),
    returnedAt: j['returnedAt'] == null ? null : DateTime.parse(j['returnedAt']),
  );
}
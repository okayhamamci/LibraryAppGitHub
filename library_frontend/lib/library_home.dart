import 'package:flutter/material.dart';
import 'package:library_frontend/Models-Providers/book.dart';
import 'package:library_frontend/Models-Providers/borrowrecord.dart';
import 'package:library_frontend/api_service.dart';
import 'package:intl/intl.dart';

String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd HH:mm').format(dt);

const kBg1 = Color(0xFFF7EFE5); // light cream
const kBg2 = Color(0xFFF1E7D0); // pale beige
const kBg3 = Color(0xFFEADBC8); // soft sand

const kCard1 = Color(0xFFFFF8EF); // card top
const kCard2 = Color(0xFFF4E7D8); // card bottom
const kBorder = Color(0xFFBDA58C); // subtle brown border

const kTextPrimary   = Color(0xFF2F241F); // deep brown
const kTextSecondary = Color(0xFF6B5E4C); // muted brown

const kPrimary  = Color(0xFF8B5E34); // warm accent (buttons/ongoing)
const kSuccess  = Color(0xFF10B981); // keep success green
const kAppBarBg = Color(0xFFF1E7D0); // light app bar

class LibraryHome extends StatefulWidget {
  const LibraryHome({super.key});
  @override
  State<LibraryHome> createState() => _LibraryHomeState();
}

class _LibraryHomeState extends State<LibraryHome> {
  int _index = 0;
  int? _userId;

  final _booksKey = GlobalKey<_AvailableBooksTabState>();
  final _borrowsKey = GlobalKey<_MyBorrowingsTabState>();


  void _onLibraryChanged() {
    _booksKey.currentState?.refresh();       
    _borrowsKey.currentState?.refreshBoth();  
  }

  @override
  void initState(){
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await ApiService.getUserIdFromToken(); 
    setState(() => _userId = id);
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          AvailableBooksTab(key: _booksKey, onChanged: _onLibraryChanged), 
          _userId == null
              ? const Center(child: CircularProgressIndicator())
              : ExploreTab(userId: _userId!), 
          MyBorrowingsTab(key: _borrowsKey, onChanged: _onLibraryChanged), 
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          setState(() => _index = i);
          if (i == 0) _booksKey.currentState?.refresh();
          if (i == 2) _borrowsKey.currentState?.refreshBoth();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Books'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), label: 'My Borrowings'),
        ],
      ),
    );
  }
}

/// ======== TAB 1: AVAILABLE BOOKS ======== ///
class AvailableBooksTab extends StatefulWidget {
  const AvailableBooksTab({this.isAdmin = false, super.key, this.onChanged, this.isArchive = false});
  final VoidCallback? onChanged;
  final bool isAdmin;
  final bool isArchive;
  @override
  State<AvailableBooksTab> createState() => _AvailableBooksTabState();
}

class _AvailableBooksTabState extends State<AvailableBooksTab> with AutomaticKeepAliveClientMixin {
  late Future<List<Book>> _future;

  @override
  void initState() {
    super.initState();
    if(widget.isArchive){
      _future = ApiService.fetchArchivedBooks();
    } else {
      _future = ApiService.fetchAvailableBooks();
    }
  }

  Future<void> _refresh() async {
    final f;
    if(widget.isArchive){
      f = ApiService.fetchArchivedBooks();
    } else {
      f = ApiService.fetchAvailableBooks();
    }
    setState(() { _future = f; });  
    await f;   
  }

  Future<void> refresh() => _refresh();

  void _openAddBookDialog(BuildContext context) {
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final descController = TextEditingController();
  final pageCountController = TextEditingController(text: '');
  double rating = 0.0;
  String? genre;

  final formKey = GlobalKey<FormState>();
  const genres = [
    'Fiction', 'Non-Fiction', 'Fantasy', 'Sci-Fi', 'Mystery',
    'Romance', 'Biography', 'History', 'Self-Help', 'Other'
  ];

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Add New Book'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Book Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: authorController,
                      decoration: const InputDecoration(
                        labelText: 'Author',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    // Genre
                    DropdownButtonFormField<String>(
                      value: genre,
                      decoration: const InputDecoration(
                        labelText: 'Genre',
                        border: OutlineInputBorder(),
                      ),
                      items: genres
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setState(() => genre = v),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Please select a genre'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    // Rating slider 0..5 (step 0.5)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rating (0–5)'),
                        Slider(
                          value: rating,
                          min: 0,
                          max: 5,
                          divisions: 10,
                          label: rating.toStringAsFixed(1),
                          onChanged: (val) =>
                              setState(() => rating = double.parse(val.toStringAsFixed(1))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Page count
                    TextFormField(
                      controller: pageCountController,
                      decoration: const InputDecoration(
                        labelText: 'Page Count',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Required';
                        }
                        final n = int.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Enter a positive number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Description (multi-line)
                    TextFormField(
                      controller: descController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final title = titleController.text.trim();
                  final author = authorController.text.trim();
                  final pageCount = int.parse(pageCountController.text.trim());
                  try {
                    await ApiService.addBook(title, author, genre!, descController.text.trim(), rating, pageCount);

                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Book added successfully')),
                      );
                      await _refresh();
                      widget.onChanged?.call();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );
}

  @override
Widget build(BuildContext context) {
  super.build(context);
  return Scaffold(
    appBar: AppBar(
      title: Text(
    !widget.isArchive ? 'Available Books' : "Archived Books",
    style: const TextStyle(color: kTextPrimary),
  ),
      backgroundColor: kAppBarBg,
      elevation: 0,
      iconTheme: const IconThemeData(color: kTextPrimary),
      actions: [
        if (widget.isAdmin)
          IconButton(
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(foregroundColor: kTextPrimary),
            onPressed: () => _openAddBookDialog(context),
          ),
      ],
    ),
    body: Container(
      // Navy gradient background
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kBg1, kBg2, kBg3],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Book>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _ErrorView(message: snap.error.toString(), onRetry: _refresh);
            }
            final books = (snap.data ?? []);
            if (books.isEmpty) {
              return const _EmptyView('No available books.');
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final crossAxisCount = w >= 1100 ? 3 : (w >= 700 ? 2 : 1);

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    // Wider cards for desktop feel
                    childAspectRatio: crossAxisCount == 1 ? 1.85 : 1.75,
                  ),
                  itemCount: books.length,
                  itemBuilder: (_, i) {
                    final b = books[i];

                    Future<void> handleAction() async {
                      try {
                        if (widget.isAdmin) {
                          await ApiService.deleteBook(b.id); // archive
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Book archived!')),
                            );
                          }
                        } else if (widget.isArchive) {
                          await ApiService.unArchiveBook(b.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Unarchived!')),
                            );
                          }
                        } else {
                          await ApiService.borrowBook(b.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Borrowed!')),
                            );
                          }
                        }
                        await _refresh();
                        widget.onChanged?.call();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    }

                    return _BookCard(
                      book: b,
                      isAdmin: widget.isAdmin,
                      isArchive: widget.isArchive,
                      onPrimaryAction: handleAction,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    ),
  );
}

  @override
  bool get wantKeepAlive => true;
}

class _BookCard extends StatelessWidget {
  final Book book;
  final bool isAdmin;
  final bool isArchive;
  final Future<void> Function() onPrimaryAction;

  const _BookCard({
    required this.book,
    required this.isAdmin,
    required this.isArchive,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final title = book.title;
    final author = book.author;
    final genre = (tryGet(() => book.genre) ?? '').toString();
    final pageCount = tryGet(() => book.pageCount) as int?;
    final rating = (tryGet(() => book.rating) as num?)?.toDouble() ?? 0;
    final desc = (tryGet(() => book.description) ?? '').toString();

    final actionLabel = isAdmin
        ? 'Archive'
        : (isArchive ? 'Unarchive' : 'Borrow');

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kCard1, kCard2],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {}, // hook for details if needed
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _CoverStub(title: title),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Author
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 13.5,
                      ),
                    ),

                    // Description (new)
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        desc,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: kTextSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Chips & rating
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (genre.isNotEmpty) _TagChip(genre),
                        if (pageCount != null && pageCount > 0)
                          _TagChip('$pageCount pages'),
                        _RatingStars(rating: rating),
                      ],
                    ),
                    const Spacer(),

                    // Action row
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: onPrimaryAction,
                          icon: Icon(
                            isAdmin
                                ? Icons.archive_rounded
                                : (isArchive
                                    ? Icons.unarchive_rounded
                                    : Icons.shopping_bag_outlined),
                            size: 18,
                          ),
                          label: Text(actionLabel),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('Details'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.14)),
                            foregroundColor: kTextPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// Simple gradient “cover” stub if you don’t have images
class _CoverStub extends StatelessWidget {
  final String title;
  const _CoverStub({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kCard2, kCard1],
        ),
        border: Border.all(color: Colors.white24.withOpacity(0.08)),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.menu_book_rounded,
        color: kPrimary,
        size: 28,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: kTextPrimary,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  final double rating; // 0..5
  const _RatingStars({required this.rating});

    @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final hasHalf = (rating - full) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < full) {
          return const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFC107));
        } else if (i == full && hasHalf) {
          return const Icon(Icons.star_half_rounded, size: 16, color: Color(0xFFFFC107));
        }
        return Icon(Icons.star_border_rounded, size: 16, color: kTextSecondary.withOpacity(0.5));
      }),
    );
  }
}

/// Small helper to safely read optional fields without crashing if absent.
/// Usage: tryGet(() => book.genre)
T? tryGet<T>(T Function() getter) {
  try {
    return getter();
  } catch (_) {
    return null;
  }
}


/// ======== TAB 2: EXPLORE (AI Recommendations) ======== ///
class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key, required this.userId});
  final int userId; // pass the current user's ID
  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> with AutomaticKeepAliveClientMixin {
  late Future<List<Book>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchAiSimilarBooks(widget.userId, topK: 3);
  }

  Future<void> _refresh() async {
    final f = ApiService.fetchAiSimilarBooks(widget.userId, topK: 3);
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
  appBar: AppBar(title: const Text('AI Recommendations')),
  body: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [kBg1, kBg2, kBg3],
        stops: [0.0, 0.55, 1.0],
      ),
    ),
    child: RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Book>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorView(message: snap.error.toString(), onRetry: _refresh);
          }
          final recs = snap.data ?? [];
          if (recs.isEmpty) {
            return const _EmptyView('No recommendations yet. Borrow at least 3 books.');
          }

          final width = MediaQuery.of(context).size.width;
          final crossAxisCount = width >= 900 ? 3 : (width >= 600 ? 2 : 1);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(), // pull-to-refresh even with few items
              itemCount: recs.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.98,
              ),
              itemBuilder: (_, i) => _RecommendationCard(book: recs[i]),
            ),
          );
        },
      ),
    ),
  ),
);

  }

  @override
  bool get wantKeepAlive => true;
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/recom.png'),
            fit: BoxFit.cover,
          ),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Stack(
          children: [
            // dark overlay for readability
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.35)),
            ),
            // content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // Top box
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (book.genre.isNotEmpty)
                              Text(book.genre, style: const TextStyle(fontSize: 12)),
                            const Spacer(),
                            Text('★ ${book.rating.toStringAsFixed(1)}',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.description.isEmpty ? 'No description.' : book.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('${book.pageCount} pages', style: const TextStyle(fontSize: 12)),
                            const Spacer(),
                            TextButton(
                              onPressed: () async {
                                try {
                                  await ApiService.borrowBook(book.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Borrowed!')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                }
                              },
                              child: const Text('Borrow'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



/// ======== TAB 3: MY BORROWINGS (Ongoing / All) ========
class MyBorrowingsTab extends StatefulWidget {
  const MyBorrowingsTab({super.key, this.onChanged, this.isAdmin = false});
  final VoidCallback? onChanged;
  final bool isAdmin;
  @override
  State<MyBorrowingsTab> createState() => _MyBorrowingsTabState();
}

class _MyBorrowingsTabState extends State<MyBorrowingsTab> with AutomaticKeepAliveClientMixin {
  late Future<List<BorrowRecord>> _ongoingFuture;
  late Future<List<BorrowRecord>> _allFuture;

  @override
  void initState() {
    super.initState();
    if(widget.isAdmin){
      _ongoingFuture = ApiService.fetchMyBorrowingsAdmin(ongoingOnly: true);
      _allFuture = ApiService.fetchMyBorrowingsAdmin(ongoingOnly: false);
    } else {
      _ongoingFuture = ApiService.fetchMyBorrowings(ongoingOnly: true);
      _allFuture = ApiService.fetchMyBorrowings(ongoingOnly: false);
    }
  }

  Future<void> _refreshOngoing() async {
    final f;
    if(widget.isAdmin){
      f = ApiService.fetchMyBorrowingsAdmin(ongoingOnly: true);
    } else {
      f = ApiService.fetchMyBorrowings(ongoingOnly: true);
    }
    setState(() { _ongoingFuture = f; });
    await f;
  }

  Future<void> _refreshAll() async {
    final f;
    if(widget.isAdmin){
      f = ApiService.fetchMyBorrowingsAdmin(ongoingOnly: false);
    } else {
      f = ApiService.fetchMyBorrowings(ongoingOnly: false);
    }
    setState(() { _allFuture = f; });
    await f;
  }
  
  Future<void> refreshBoth() async {
    await Future.wait([_refreshOngoing(), _refreshAll()]);
  }

  @override
Widget build(BuildContext context) {
  super.build(context);
  return DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('My Borrowings', style: TextStyle(color: Colors.white),),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: const TabBar(
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: kTextPrimary,
          unselectedLabelColor: Colors.white70,
          indicator: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary, Color(0xFFB08968)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          tabs: [
            Tab(text: 'Ongoing'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: Container(
        // Navy gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kBg1, kBg2, kBg3],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: TabBarView(
          children: [
            _BorrowingsList(
              future: _ongoingFuture,
              onRefresh: _refreshOngoing,
              showReturn: true,
              onChanged: widget.onChanged,
              isAdmin: widget.isAdmin,
            ),
            _BorrowingsList(
              future: _allFuture,
              onRefresh: _refreshAll,
              showReturn: false,
              onChanged: widget.onChanged,
              isAdmin: widget.isAdmin,
            ),
          ],
        ),
      ),
    ),
  );
}


  @override
  bool get wantKeepAlive => true;
}

class _BorrowingsList extends StatefulWidget {
  final Future<List<BorrowRecord>> future;
  final Future<void> Function() onRefresh;
  final bool showReturn;
  final VoidCallback? onChanged;
  final bool isAdmin;
  const _BorrowingsList({
    required this.future,
    required this.onRefresh,
    required this.showReturn,
    this.onChanged,
    this.isAdmin = false,
  });

  @override
  State<_BorrowingsList> createState() => _BorrowingsListState();
}

class _BorrowingsListState extends State<_BorrowingsList> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: FutureBuilder<List<BorrowRecord>>(
        future: widget.future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorView(message: snap.error.toString(), onRetry: widget.onRefresh);
          }
          final items = snap.data ?? [];
          if (items.isEmpty) return const _EmptyView('Nothing here yet.');

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final r = items[i];
              final ongoing = r.returnedAt == null;

              Future<void> handleReturn() async {
                try {
                  await ApiService.returnBook(r.bookId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Returned!')),
                    );
                  }
                  await widget.onRefresh();
                  widget.onChanged?.call();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _BorrowCard(
                  record: r,
                  showReturn: widget.showReturn && ongoing && !widget.isAdmin,
                  onReturn: handleReturn,
                ),
              );
            },
          );
        },
      ),
    );
  }
}


class _BorrowCard extends StatelessWidget {
  final BorrowRecord record;
  final bool showReturn;
  final Future<void> Function()? onReturn;

  const _BorrowCard({
    required this.record,
    this.showReturn = false,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    
    final ongoing = record.returnedAt == null;

    final statusText = ongoing ? 'Ongoing' : 'Returned';
    final statusColor = ongoing ? kPrimary : kSuccess;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kCard1, kCard2],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {}, 
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 72,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withOpacity(0.07),
                child: Icon(
                  ongoing ? Icons.timelapse_rounded : Icons.check_circle_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kTextSecondary,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(label: statusText, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DatePill(
                          icon: Icons.login_rounded,
                          label: 'Borrowed',
                          value: _fmt(record.borrowedAt),
                        ),
                        if (record.returnedAt != null)
                          _DatePill(
                            icon: Icons.logout_rounded,
                            label: 'Returned',
                            value: _fmt(record.returnedAt!),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Actions
                    Row(
                      children: [
                        if (showReturn && onReturn != null)
                          ElevatedButton.icon(
                            onPressed: onReturn,
                            icon: const Icon(Icons.keyboard_return_rounded, size: 18),
                            label: const Text('Return'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(  
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        const Spacer(),
                        // Optional secondary action placeholder
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('Details'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.14)),
                            foregroundColor: kTextPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DatePill({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}


class LibraryAdmin extends StatefulWidget{

  const LibraryAdmin({super.key});

  @override
  State<LibraryAdmin> createState() => _LibraryAdminState();
}

class _LibraryAdminState extends State<LibraryAdmin> {
  int _index = 0;

  final _booksKey = GlobalKey<_AvailableBooksTabState>();
  final _borrowsKey = GlobalKey<_MyBorrowingsTabState>();
  final _archiveKey = GlobalKey<_AvailableBooksTabState>();

  void _onLibraryChanged() {
    _booksKey.currentState?.refresh();      
    _archiveKey.currentState?.refresh();  
    _borrowsKey.currentState?.refreshBoth();  
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          AvailableBooksTab(key: _booksKey, onChanged: _onLibraryChanged, isAdmin: true), 
          AvailableBooksTab(key: _archiveKey, onChanged: _onLibraryChanged, isArchive: true,), 
          MyBorrowingsTab(key: _borrowsKey, onChanged: _onLibraryChanged, isAdmin: true), 
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          setState(() => _index = i);
          if (i == 0) _booksKey.currentState?.refresh();
          if (i == 1) _archiveKey.currentState?.refresh(); 
          if (i == 2) _borrowsKey.currentState?.refreshBoth();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Books'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Archive'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), label: 'Borrowings'),
        ],
      ),
    );
  }
}



class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => onRetry(), child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String text;
  const _EmptyView(this.text);
  @override
  Widget build(BuildContext context) => Center(child: Text(text));
}
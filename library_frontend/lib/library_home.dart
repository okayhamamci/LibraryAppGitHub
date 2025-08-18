import 'package:flutter/material.dart';
import 'package:library_frontend/Models-Providers/book.dart';
import 'package:library_frontend/Models-Providers/borrowrecord.dart';
import 'package:library_frontend/api_service.dart';
import 'package:intl/intl.dart';

String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd HH:mm').format(dt);

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
        title: Text(!widget.isArchive ? 'Available Books' : "Archived Books"),
        actions: [
  if (widget.isAdmin)
    IconButton(
      icon: const Icon(Icons.add),
      onPressed: () {
        _openAddBookDialog(context);
      },
    ),
],
      ),
      body: RefreshIndicator(
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
            final books = snap.data!;
            if (books.isEmpty) return const _EmptyView('No available books.');
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemBuilder: (_, i) {
                final b = books[i];
                return ListTile(
                  leading: const Icon(Icons.book_outlined),
                  title: Text(b.title),
                  subtitle: Text(b.author),
                  trailing: TextButton(
                  onPressed: () async {
                    try {
                      if (widget.isAdmin) {
                        // Remove book
                        await ApiService.deleteBook(b.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Book archived!')),
                          );
                        }
                      } else if(widget.isArchive) {
                        await ApiService.unArchiveBook(b.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Unarchived!')),
                          );
                        }
                      }
                      else {
                        // Borrow book
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
                  },
                  child: Text(widget.isAdmin 
                  ? 'Archive' 
                  : widget.isArchive ? "Unarchive" :'Borrow'),
                ),
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: books.length,
            );
          },
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
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
      body: RefreshIndicator(
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

            // 3 panels; responsive fallback to 1 or 2 columns on narrow screens
            final width = MediaQuery.of(context).size.width;
            final crossAxisCount = width >= 900 ? 3 : (width >= 600 ? 2 : 1);

            return Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                itemCount: recs.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.98, // tall card (like your sketch)
                ),
                itemBuilder: (_, i) => _RecommendationCard(book: recs[i]),
              ),
            );
          },
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
          title: const Text('My Borrowings'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Ongoing'),
            Tab(text: 'All'),
          ]),
        ),
        body: TabBarView(
          children: [
            _BorrowingsList(future: _ongoingFuture, onRefresh: _refreshOngoing, showReturn: true, onChanged: widget.onChanged, isAdmin: widget.isAdmin),
            _BorrowingsList(future: _allFuture, onRefresh: _refreshAll, showReturn: false, onChanged: widget.onChanged, isAdmin: widget.isAdmin),
          ],
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
  const _BorrowingsList({required this.future, required this.onRefresh, required this.showReturn, this.onChanged, this.isAdmin = false});

  @override
  State<_BorrowingsList> createState() => _BorrowingsListState();
}

class _BorrowingsListState extends State<_BorrowingsList> {

  @override
  void initState() {
    super.initState();
  }

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
          final items = snap.data!;
          if (items.isEmpty) {
            return const _EmptyView('Nothing here yet.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = items[i];
              final ongoing = r.returnedAt == null;
              return ListTile(
                leading: Icon(ongoing ? Icons.timelapse_outlined : Icons.check_circle_outline),
                title: Text(r.title),
                subtitle: Text(
                '${r.author}\nBorrowed: ${_fmt(r.borrowedAt)}'
                '${r.returnedAt != null ? ' |  Returned: ${_fmt(r.returnedAt!)}' : ''}',
              ),
                isThreeLine: true,
                trailing: (widget.showReturn && ongoing && !widget.isAdmin)
                    ? TextButton(
                        onPressed: () async {
                          try {
                            //print( "${r.bookId} : ${r.id}");
                            await ApiService.returnBook(r.bookId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Returned!')),
                              );
                            }
                            await widget.onRefresh();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                        child: const Text('Return'),
                      )
                    : null,
              );
            },
          );
        },
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
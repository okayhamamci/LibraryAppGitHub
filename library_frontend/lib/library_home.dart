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

  final _booksKey = GlobalKey<_AvailableBooksTabState>();
  final _borrowsKey = GlobalKey<_MyBorrowingsTabState>();


  void _onLibraryChanged() {
    _booksKey.currentState?.refresh();       
    _borrowsKey.currentState?.refreshBoth();  
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          AvailableBooksTab(key: _booksKey, onChanged: _onLibraryChanged), 
          const EmptyTab(),
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
        final titleController = TextEditingController();
        final authorController = TextEditingController();

        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Add New Book'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Book Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: authorController,
                    decoration: const InputDecoration(
                      labelText: 'Author',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final author = authorController.text.trim();

                    if (title.isEmpty || author.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill both fields')),
                      );
                      return;
                    }
                    try {
                      await ApiService.addBook(title, author);
                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Book added successfully')),
                        );
                        await _refresh(); // refresh list
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

/// ======== TAB 2: EMPTY PLACEHOLDER ======== ///
class EmptyTab extends StatelessWidget {
  const EmptyTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('AI Recommendation System')),
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
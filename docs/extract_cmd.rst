=================
 Extract Command
=================

This command extracts FB2 books from a ZIP archive into your incoming library folder (``library_dir``).

- Works with regular ZIP files and very large archives (larger than 4.5 GB).
- For large archives it automatically uses the external ``7z`` tool and prints a notice.
- Creates any needed folders automatically.

Example. Extract books from the ``my_books.zip`` archive::

  bookweald extract my_books.zip


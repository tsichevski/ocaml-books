================================
Bookweald — FB2 Library Manager
================================

Bookweald is a fast, lightweight **command-line tool** (and OCaml library) designed for users who manage large collections of FictionBook (FB2) ebooks.

It helps you:

- Extract books from ZIP archives without unpacking everything at once
- Automatically organize your library by author (creating neat folders like ``Author Name/``)
- Validate FB2 files for correctness
- Build a searchable index of your entire collection
- Handle different character encodings commonly found in older FB2 files
- Manage author name variations and exclude unwanted books

Key Features
------------

- **Streaming decompression** — works directly with large ZIP archives
- **Smart grouping** — moves books into author-named subdirectories
- **Validation** — checks FB2 files against the FictionBook 2.1 standard
- **Indexing** — builds a quick database for searching your library
- **Author aliases & blacklisting** — clean up messy author names and ignore broken book files
- **Minimal dependencies** — fast and lightweight

Command Line
------------

- ``extract`` — extract FB2 files from ZIP archive(s)
- ``validate`` — fully parse all FB2 files as XML
- ``group`` — parse FB2 files and move them into author-named subdirectories
- ``index`` — add files to the index

Project Links
-------------

- **Repository**: https://github.com/tsichevski/bookweald
- **Documentation**: ``docs/index.rst`` (built with Sphinx)
- **Issues & Feedback**: https://github.com/tsichevski/bookweald/issues

License
-------

MIT License — feel free to use, modify, and contribute!

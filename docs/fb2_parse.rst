=================
 Parse FB2 files
=================

The FB2 XML schema: http://www.fictionbook.org/index.php/Eng:XML_Schema_Fictionbook_2.1

.. note::
   The original schema file is not always strictly valid XML.
   Use the locally fixed version ``FictionBook2.1.xsd`` for reference or validation.

Author info
-----------

Author information is stored inside any number of ``<author>`` elements, which can appear in:

- ``<title-info>`` (most reliable / bibliographic data)
- ``<document-info>`` (often contains garbage: scanner/editor signatures, dummy values)

Both sections are children of the root-level ``<description>`` element inside ``<FictionBook>``.

.. note::
   Prefer authors from ``<title-info>`` when present.
   Data in ``<document-info>`` is frequently unreliable and should be used only as fallback.

Example::

   <description>
     <title-info>
       <author>
         <first-name>Аркадий</first-name>
         <middle-name>Натанович</middle-name>
         <last-name>Стругацкий</last-name>
       </author>
       <author>
         <first-name>Борис</first-name>
         <middle-name>Натанович</middle-name>
         <last-name>Стругацкий</last-name>
       </author>
     </title-info>
     <document-info>
       <author>
         <first-name>Alexx</first-name>
         <last-name></last-name>
       </author>
     </document-info>
   </description>

We define an ``author`` record type and aim to collect all matching ``<author>`` blocks as an ``author list`` in document order.

The **first** author in this list is considered principal and is used to form target directory names / filenames during organization.

Current implementation (March 2026)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Implemented in ``lib/fb2_parse.ml`` using ``xmlm`` (streaming XML parser).

Only one author is currently handled: all matching fields (first/middle/last name, nickname, etc.) are extracted into the same record — later occurrences **overwrite** previous ones.

This produces acceptable results for:

- single-author books
- many co-authored works where the same names are repeated

No multi-author grouping exists yet; each book is assigned to exactly one author folder.

Legacy encoding support — fully implemented
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Many older Russian FB2 files use legacy 8-bit encodings (primarily ``windows-1251`` / CP1251, sometimes ``KOI8-R``) instead of UTF-8, even when declaring such in the XML prologue.

``xmlm`` natively supports only Unicode-friendly encodings (UTF-8/16, ISO-8859-1, and later Latin-9). It fails early on CP1251/KOI8-R input.

Solution (now in place and tested):

- A lightweight, non-validating manual parser scans the raw input bytes for the XML declaration (``<?xml ... ?>``).
- It extracts the ``encoding`` attribute value using simple ASCII-safe substring matching (safe because attribute syntax is ASCII).
- If a legacy encoding (CP1251, KOI8-R, etc.) is detected:
  - A recoding stage converts the entire input stream to UTF-8 on-the-fly.
  - The recoded bytes are fed to ``xmlm`` via a custom input function.
- If no declaration or UTF-8 is declared → pass through unchanged.
- Fallback: assume UTF-8 if no usable declaration is found.

This approach avoids full pre-loading of files and works with streaming input.

Tested successfully on:

- Pure UTF-8 files (with/without declaration)
- CP1251 files with correct Cyrillic title/author display after conversion
- Mixed/edge cases: malformed declarations, missing prologue, very long attribute lists
- Large archives containing legacy-encoded books

.. note::
   Recoding tables/functions are implemented for CP1251 → UTF-8 (primary case) and KOI8-R → UTF-8.
   Add more legacy encodings as needed (rare in FB2 collections).

Planned improvements
~~~~~~~~~~~~~~~~~~~~

- Collect multiple authors into a list (parse all ``<author>`` blocks in order)
- Choose principal author with heuristics:
  - first from ``<title-info>``
  - prefer blocks with non-empty ``<last-name>``
  - most complete / longest name
- Pretty-print joined author names for display/index („Аркадий и Борис Стругацкие“, „Стругацкий А. Н., Стругацкий Б. Н.“)
- Use full author list for folder name disambiguation when needed
- Add support for book series and sequence info (``<sequence>`` element)
- Build persistent index (s-expression dump, or lightweight library like ``index`` / ``irmin``)
- Simple CLI/TUI navigator for author → title browsing

Future extensions
~~~~~~~~~~~~~~~~~

- Handle ZIP archive import with on-the-fly extraction and parsing
- Optional validation against fixed FB2 schema (post-parsing checks)
- Configuration file for encoding preferences or fallback rules
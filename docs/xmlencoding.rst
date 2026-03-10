==================================
Handling Non-Unicode FB2 Encodings
==================================

Problem
-------

The FB2 parser uses ``xmlm`` for XML parsing, which natively supports only Unicode encodings (UTF-8, UTF-16, ISO-8859-1). However, many legacy FB2 files—particularly Russian publications—declare non-Unicode encodings such as ``windows-1251`` (CP1251) in their XML declarations:

.. code-block:: xml

   <?xml version="1.0" encoding="windows-1251"?>
   <FictionBook>...</FictionBook>

When ``xmlm`` encounters such files, it attempts to parse from the beginning, but fails with a decoding error because the file bytes are not in a Unicode encoding. This happens **before** we have a chance to read the encoding declaration.

Example XML Declarations
------------------------

UTF-8 (no conversion needed)::

   <?xml version="1.0" encoding="UTF-8"?>

CP1251 (legacy Russian, raw bytes)::

   <?xml version="1.0" encoding="windows-1251"?>
   [... rest of file in CP1251 bytes ...]

No declaration (defaults to UTF-8)::

   <FictionBook>...</FictionBook>

Why Not Use Xmlm to Detect Encoding?
------------------------------------

``xmlm`` itself reads and validates character encoding from XML declaration. If the encoding is not one of supported by ``xmlm``, it will raise::

   Xmlm.Error (pos, `Unexpected_eoi | `Invalid_char | ...)

Solution
--------

Implement a **manual, non-validating parser** for the XML declaration only:

1. **Extract Raw XML Declaration Bytes**
2. **Parse Encoding Attribute**

   From the raw declaration bytes, extract the encoding using simple string matching::
   
      encoding="windows-1251"
   
   This substring is also ASCII-safe in all encodings.

3. **Provide custom input for xmlm**, either:
   #. Create custom input channel with recoding (how hard is this?)
   #. ``Xmlm`` allows input from a function: provide custom input function with recoding bytes from original channel

Testing
-------

Test files should include:

- UTF-8 encoded FB2 with declaration
- UTF-8 encoded FB2 without declaration
- CP1251 encoded FB2 with Cyrillic author/title and declaration
- Minimal files (just declaration, no content)
- Large declaration (many attributes)
- Truncated or malformed declaration
- Empty file
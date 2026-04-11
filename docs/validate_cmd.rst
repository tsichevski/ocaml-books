.. _validate_cmd:

==================
 Validate Command
==================

The ``validate`` command checks all FB2 files in your incoming library folder for basic correctness.

- Scans recursively for ``*.fb2`` and ``*.fb2.zip`` files.
- Performs a quick check that each file is well-formed XML.
- Adds any invalid or broken files to the blacklist (``blacklist.txt`` by default) so they are ignored in future runs.
- This is a fast sanity check only.


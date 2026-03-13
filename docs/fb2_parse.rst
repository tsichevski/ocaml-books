=================
 Parse FB2 files
=================

The FB2 XML schema: http://www.fictionbook.org/index.php/Eng:XML_Schema_Fictionbook_2.1

.. note::
   The original schema file is not always strictly valid XML. Use the locally fixed version ``FictionBook2.1.xsd`` for reference or validation.

Author info
-----------

Author information is stored inside any number of ``<author>`` elements, which can appear in:

- ``<title-info>`` (most reliable / bibliographic data)
- ``<document-info>`` (sometimes contains garbage or editor information)

Both sections are children of the root-level ``<description>`` element inside ``<FictionBook>``.

.. note::
   Data in ``<document-info>`` is often unreliable (scanner/editor signatures, dummy values).
   Prefer ``<title-info>`` authors when possible.

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

We define an ``author`` record type and aim to collect all matching ``<author>`` blocks as a ``author list`` in document order.

The **first** author in this list is considered principal and is used to form target directory names / filenames during organization.

Current implementation approach
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Only one author is handled. All matching author field data (first/middle/last name) are extracted into the same reference-style variables — later occurrences **overwrite** previous ones.

This gives reasonable results for single-author books and many co-authored works where the same names are repeated.

Planned improvements:

- Collect multiple authors into a list
- Decide principal author using heuristics (e.g. first in ``<title-info>``, non-empty fields, longest name…)
- Join multiple authors for display („Аркадий и Борис Стругацкие“)
- Use full author list for disambiguation when creating index or folder names (e.g. suffix or combined key)

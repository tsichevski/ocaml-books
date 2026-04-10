=================
 Book validation
=================

All books in the repository must match these conditions:

#. Have valid XML format with one of the following encodings:

   #. ``utf8``
   #. ``windows-1251`` (``cp1251``)
   #. ``windows-1252`` (``cp1252``)
   #. ``windows-1255`` (``cp1255``)
   #. ``koi8-r``
   #. ``iso-8859-1``
   #. ``iso-8859-5``

#. Have title at the ``FictionBook/description/title-info/book-title`` path

All autors in the repository must match these conditions:

#. Have at least one of ``last_name`` or ``first_name`` defined.

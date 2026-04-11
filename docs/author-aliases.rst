==============
Author Aliases
==============

.. index:: author aliases, canonical authors, aliases, fb2 authors
           
The same real author may appear under slightly different name strings in FB2 files. 
An alias mechanism allows mapping every variant to a single canonical author record.

Key Features
------------

- Provide an alias table that maps every variant name to one canonical author.
- Canonical author data is used for grouping books by author and for naming author sub-directories on disk.
- The alias mapping is maintained in a human-readable JSON file intended for manual editing by the user.

Aliases File
------------

The aliases mapping is contained in a JSON file. Its location is defined in the tool configuration under the key ``alias_file``::

   {
       ...
       "alias_file": "/some_path_to/aliases.json",
       ...
   }

There is no default for the alias file location. If the file is not configured, author aliases are not used.

The file is a JSON object where each key is a canonical author name and the value is an array of all known alias strings that should map to it.

Example::

   {
     "Иванов Иван Иванович": [
       "Иванов И. И.",
       "Иванов Иван",
       "Ivanov I.I.",
       "И.И. Иванов"
     ],
     "Петров Сергей Петрович": [
       "Петров С.",
       "Petrov S."
     ]
   }
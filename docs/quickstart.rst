=====================
Bookweald Quick Start
=====================

This tutorial describes the usual workflow with Bookweald.  
The tool was created and tested on Ubuntu Linux, so this tutorial assumes you are on Linux.

In this tutorial we will:

- Configure the tool
- Add books
- Validate the book files integrity
- Register books in a PostgreSQL database

Configuration
-------------

Before you begin, you will most probably have to configure the tool.  
The configuration is located in the file ``~/.config/bookweald/config.json``, which has JSON format.

You can create this file manually, but the simplest way is by running::

  bookweald init

This will create the following minimal configuration file::

  {
    "library_dir": "/home/jondeer/books/incoming",
    "target_dir": "/home/jondeer/books/organized",
    "database": {}
  }

In this minimal setup, these two directories are defined:

- ``library_dir``: main directory containing books to process
- ``target_dir``: the directory to move books to when using the ``organize`` command.

The "jondeer" here stands for the current system user name.  
If needed, replace the ``library_dir`` field value with the directory where you will put your FB2 files.  
For now, do not make any other changes.

Add Books
---------

Next, you will need books. Bookweald supports FB2 files with the ``.fb2`` extension or their ZIPped variants with the ``.fb2.zip`` extension.

Books shall be placed into ``library_dir``. You can copy them yourself, or you can extract books from a ZIP archive.  
You can do this with the ``unzip`` program, or using Bookweald::

  bookweald extract <path_to_a_zip_archive>

This command will extract the contents of ``<path_to_a_zip_archive>`` to ``library_dir``.

Validate Books
--------------

Next, you will need to check that the files are valid FB2 files. You can do this with the ``validate`` command::

  bookweald validate

This command scans the ``library_dir`` recursively for FB2 files and checks the file format.  
Invalid files are registered in the blacklist file. By default, this blacklist file is named ``blacklist.txt`` and is located in the directory where the program is executed.

.. note::
   At the moment of writing, the command validates only that the files are valid XML files, not that they are valid FB2 files.

Create and Initialise the Database
----------------------------------

Bookweald allows you to store book information in a PostgreSQL database.

In this tutorial we will use the default DB name and connection parameters:

- host: ``localhost``
- port: ``5432``
- application user: ``books``
- application password: ``books``
- DB name: ``books``
- admin user (used to create DB schema): ``admin``
- admin user password: ``admin``

Create a new database and initialise it with the DB schema:

#. Create the DB with any PostgreSQL tool, e.g.::

     createdb -w -U admin -h localhost -p 5432 books

#. Initialise the DB schema with::

     bookweald schema-init

#. Check the result. Run::

     psql -U books -w books

   and enter::

     \dt

   You should see::

                List of relations
      Schema |     Name     | Type  | Owner
     --------+--------------+-------+-------
      public | book_authors | table | admin
      public | books        | table | admin
      public | persons      | table | admin
     (3 rows)

Indexing Books
--------------

Next, as soon as the DB is ready, we will add the book information to it::

  bookweald index

The log output should end with a message similar to this::

  All 123 files indexed successfully

(where 123 is the actual number of files).

Fast check the results with something like this::

  echo "SELECT id, title, encoding, filename FROM books WHERE title LIKE 'Война и мир';" | psql -U books -w books

The output will look like this::
  
       id   |    title    |   encoding   | filename 
    --------+-------------+--------------+--------------
     100799 | Война и мир | windows-1251 | war_and_peace
     363574 | Война и мир | utf-8        | wap
     352545 | Война и мир | utf-8        | 12345
    (3 rows)
  

==============================
 DB Schema Initialize Command
==============================

The ``schema-init`` command sets up the PostgreSQL database tables needed to store book information.

- Creates the tables for books, authors, and the links between them.
- Adds indexes and constraints.
- Uses the admin credentials from your configuration.

Example::

  bookweald schema-init


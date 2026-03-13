(** FB2 metadata extraction (streaming / SAX-style with xmlm).

    This module parses FB2 files efficiently without loading the entire file into memory.
    It stops parsing as soon as the first [<title-info>] element is fully processed.

    Assumptions (current implementation):
    - All input files are valid UTF-8 (no encoding detection or conversion)
    - Only the first [<title-info>] block is processed
    - Authors are collected from both [<title-info>] and [<document-info>] sections
    - Only one author block per section is collected (first occurrence)

    Dependencies: xmlm (streaming XML parser), Recoding_channel (internal byte recoder)

    Raises Fb2_parse_error on parse failures (missing required tags, malformed XML, etc.)
*)

open Book

(** [parse_title_author path] parses the FB2 file at [path] using streaming XML parsing.

    - Reads the file incrementally (does not load full content into memory)
    - Automatically detects encoding from XML declaration and recodes to UTF-8
    - Collects title and all authors from the first [<title-info>] or [<document-info>]
    - Stops parsing after the closing </title-info> or </document-info> tag

    @param path Path to the FB2 file
    @return [title_info] record with extracted metadata
    @raise Fb2_parse_error if required elements are missing or XML is malformed
    @raise Failure if the declared encoding is unsupported
*)
val parse_title_author : string -> title_info
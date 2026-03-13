type author = {
  first_name: string option;
  middle_name: string option;
  last_name: string option;
}

type title_info = {
  title: string option;
  authors: author list;
  lang: string option;
  genre: string option;
}


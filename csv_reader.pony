use "collections/persistent"
use "itertools"
use "files"


class CsvReader
  """
  Read and parse csv files with respect of RFC 4180
  cf https://tools.ietf.org/html/rfc4180
  """
  var _reader : _Reader
  var _has_title : Bool = false
  var _title : Array[String] val = []
  var _delim : String = ";"

  new from_file(
    file_path: FilePath,
    with_title : Bool = false,
    delim : String = ",") ?
  =>
    """
    Create a csv reader from a file
    """
    _has_title = with_title
    _delim = delim
    match OpenFile(file_path)
    | let file: File =>
      _reader = _FileReader(file)
    else
      error
    end
    _init()

  new from_bytes(
    data: ByteSeq,
    with_title : Bool = false,
    delim : String = ",")
  =>
    """
    Create a csv reader from an array of U8 or a string
    """
    _has_title = with_title
    _delim = delim
    _reader = _BytesReader(data)
    _init()

  fun title() : Array[String] val =>
    """
    Get the first line as array of string
    If reader was created with with_title = false, returned array will be empty
    """
    _title

  fun ref lines() : Iterator[Array[String] iso^] =>
    """
    Return an iterator to all lines of csv data.
    Data stream will be read gradually, as lines are read.
    If reader was created with titles, the first line is skipped.
    """
    let lines_it = _reader.lines()
    if _has_title then try lines_it.next()? end end
    CsvReaderLines(lines_it, _delim)

  fun ref lines_map() : Iterator[Map[String, String]] =>
    """
    Return an iterator to all lines.
    Each line is a map of values with title as key.
    Data stream will be read gradually, as lines are read.
    If reader was created without titles, all line map will be empty.
    """
    CsvReaderLinesMap(lines(), _title)

  fun ref all_lines() : Array[Array[String] val] iso^ =>
    """
    Return all csv data as array of lines.
    Data stream is all read at once.
    If reader was created with titles, the first line is skipped.
    """
    let lines_it = lines()
    recover
      var result = Array[Array[String] val]
      while lines_it.has_next() do
        try
          result.push(lines_it.next()?)
        end
      end
      result
    end

  fun ref all_lines_map() : Array[Map[String, String] val] iso^ =>
    """
    Return all csv data as array of lines.
    Each line is a map of values with title as key.
    Data stream is all read at once.
    If reader was created without titles, all line map will be empty.
    """
    let lines_it = lines_map()
    recover
      var result = Array[Map[String, String] val]
      while lines_it.has_next() do
        try
          result.push(lines_it.next()?)
        end
      end
      result
    end

  fun ref column(index : USize) : Array[String] iso^ ? =>
    """
    Return the column identified by index (from 0), as array of string values.
    If reader was created with titles, the first line is skipped.
    Everytime this function is called, all data stream is read.
    """
    let lines_it = lines()
    recover
      var result = Array[String]
      while lines_it.has_next() do
        result.push(lines_it.next()?(index)?)
      end
      result
    end

  fun ref all_columns() : Array[Array[String] val] iso^ ? =>
    """
    Return all csv data as array of columns.
    Data stream is all read at once.
    If reader was created with titles, the first line is skipped.
    """
    var cols = _all_columns_ref()?
    recover
      // convert Array[String] val to Array[String] ref elements
      var result = Array[Array[String] val]
      while cols.size() > 0 do
        (let up, let others) = (consume cols).chop(1)
        result.push((consume val up)(0)?)
        cols = consume others
      end
      result
    end

  fun ref all_columns_map() : Map[String, Array[String] val] val ? =>
    """
    Return all csv data as map of columns, with title as keys.
    Data stream is all read at once.
    """
    let cols = all_columns()?
    let cols_values = (consume cols).values()
    let title_values = _title.values()
    recover
      var result = Map[String, Array[String] val]
      while cols_values.has_next() and title_values.has_next() do
        try
          result = result(title_values.next()?) = cols_values.next()?
        end
      end
      result
    end

  fun ref _all_columns_ref() : Array[Array[String] ref] iso^ ? =>
    let lines_it = lines()
    recover
      var result = Array[Array[String] ref]
      // First line of columns
      if lines_it.has_next() then
        let line = lines_it.next()?
        Iter[String]((consume val line).values())
          .map[Array[String]]({(t) => [t]})
          .collect(result)
      end

      // all lines
      while lines_it.has_next() do
        try
          let line = lines_it.next()?
          for (i, v) in Iter[String]((consume val line).values()).enum() do
            result(i)?.push(v)
          end
        end
      end

      result
    end

  fun ref _init() =>
    if _has_title then _read_title() end

  fun ref _read_title() =>
    try
      _title = _CsvParser.parse_next_line(_reader.lines(), _delim)?
    end


class CsvReaderLines is Iterator[Array[String]]
  var _lines : Iterator[String] ref
  var _delim : String

  new create(lines : Iterator[String] ref, delim : String) =>
    _lines = lines
    _delim = delim

  fun ref has_next() : Bool =>
    _lines.has_next()

  fun ref next() : Array[String] iso^ ? =>
    _CsvParser.parse_next_line(_lines, _delim)?


class CsvReaderLinesMap is Iterator[Map[String, String]]
  var _lines_reader : Iterator[Array[String]] ref
  var _title : Array[String] val

  new create(
    lines_reader : Iterator[Array[String]] ref,
    title
    : Array[String] val)
  =>
    _lines_reader = lines_reader
    _title = title

  fun ref has_next() : Bool =>
    _lines_reader.has_next()

  fun ref next() : Map[String, String] val^ ? =>
    let line = _lines_reader.next()?
    let line_values = line.values()
    let title_values = _title.values()
    recover
      var result = Map[String, String]
      while line_values.has_next() and title_values.has_next() do
        result = result(title_values.next()?) = line_values.next()?
      end
      result
    end


trait _Reader
  fun ref lines(): Iterator[String] ref


actor Main
  new create(env: Env) =>
    env.out.print("Pony CSV reader test")
    try
      let fileName = env.args(1)?
      env.out.print("Read file " + fileName)
      let file_path = FilePath(env.root as AmbientAuth, fileName)?
      try
        var reader = CsvReader.from_file(file_path where with_title = true)?

        // Print titles
        let titles = Iter[String](reader.title().values()).fold[String](
          "", {(st, field) => if st.size() == 0 then field
                              else st + " | " + field end})
        env.out.print("Titles:")
        env.out.print(titles)

        // get all lines
        //let lines = reader.all_lines()
        //env.out.print(lines.size().string() + " lines")

        // get all lines as map
        //let lines = reader.all_lines_map()
        //env.out.print(lines.size().string() + " lines")

        // get all columns
        let cols = reader._all_columns_ref()?
        env.out.print(cols.size().string() + " columns")
      else
        env.out.print("Cannot read file")
      end
    else
      env.out.print("Please provide a csv file as argument")
    end

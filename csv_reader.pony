use "files"


class CsvReader
  var _reader : _Reader
  var _has_title : Bool = false
  var _title : Array[String] val = []
  var _delim : String = ";"

  new fromFile(
    filePath: FilePath,
    with_title : Bool = false,
    delim : String = ";") ?
  =>
    _has_title = with_title
    _delim = delim
    match OpenFile(filePath)
    | let file: File =>
      _reader = _FileReader(file)
    else
      error
    end
    _init()

  new fromBytes(
    data: ByteSeq,
    with_title : Bool = false,
    delim : String = ";")
  =>
    _has_title = with_title
    _delim = delim
    _reader = _BytesReader(data)
    _init()

  fun title() : Array[String] val =>
    _title

  fun ref lines() : Iterator[Array[String]] =>
    let all_lines = _reader.lines()
    if _has_title then try all_lines.next()? end end
    CsvReaderLines(all_lines, _delim)

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


trait _Reader
  fun ref lines(): Iterator[String] ref


/*
actor Main
  new create(env: Env) =>
    env.out.print("Pony CSV reader")
    try
      let fileName = env.args(1)?
      env.out.print("Read file " + fileName)
      let filePath = FilePath(env.root as AmbientAuth, fileName)?
      try
        var reader = CsvReader.fromFile(filePath where with_title = true)?
        for title in reader.title().values() do
          env.out.print(title)
        end
      else
        env.out.print("Cannot read file")
      end

      let invar = "Maman\nBateaux"
      var reader = CsvReader.fromBytes(invar.array())
    else
      env.out.print("Please provide a csv file as argument")
    end
*/

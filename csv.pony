use "files"


trait Reader
  fun ref lines(): Iterator[String] ref


class FileReader is Reader
  var _file: File

  new create(file: File) =>
    _file = file

  fun ref lines() : Iterator[String] ref =>
    _file.seek_start(0)
    FileLines(_file)


class BytesReader is (Reader & Iterator[String])
  var _bytes: Array[U8 val] val
  var _position: USize = 0

  new create(str: ByteSeq) =>
    _bytes = []
    match str
    | let s: String =>
      _bytes = s.array()
    | let a: Array[U8 val] val =>
      _bytes = a
    end

  fun has_next() : Bool =>
    _position < _bytes.size()

  fun ref next() : String ? =>
    if _position >= _bytes.size() then error end
    let pos1 = _position
    let pos2 = _next_new_line()
    _position = pos2 + 1
    String.from_array(_bytes.trim(pos1, pos2))

  fun ref lines(): Iterator[String] ref =>
    _position = 0
    this

  fun _next_new_line(): USize =>
    var pos = _position
    try
      while _bytes(pos)? != '\n' do
        pos = pos + 1
      end
    end
    pos


class CsvReader
  var _reader : Reader
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
      _reader = FileReader(file)
    else
      error
    end
    _init()?

  new fromBytes(
    data: ByteSeq,
    with_title : Bool = false,
    delim : String = ";") ?
  =>
    _has_title = with_title
    _delim = delim
    _reader = BytesReader(data)
    _init()?

  fun title() : Array[String] val =>
    _title

  fun ref dump(out: OutStream) =>
    for line in _reader.lines() do
      out.print("#" + line + "#")
    end

  fun ref _init()? =>
    if _has_title then _read_title()? end

  fun ref _read_title()? =>
    let line = _reader.lines().next()?
    _title = line.split_by(_delim)

  fun ref _parse_line(line : String ref) : Array[String] iso^ =>
    let result = recover Array[String] end
    var previous : String val = ""

    for value in line.split_by(_delim).values() do
      if previous.size() > 0 then
        if _is_end_quote(value) then
          previous = previous + value.trim(0, value.size() - 1)
          result.push(_unescape_quotes(previous))
          previous = ""
        else
          previous = previous + value
        end
      else 
        if _is_begin_quote(value) then
          if _is_end_quote(value) then
            result.push(_unescape_quotes(value.trim(1, value.size() - 1)))
          else
            previous = value.trim(1)
          end
        else
          result.push(value)
        end
      end
    end
    consume result

  fun _unescape_quotes(value : String box) : String iso^ =>
    """ Replace '""' with '"' in a string """
    recover
      let result : String ref = value.clone()
      result.replace("\"\"", "\"")
      result
    end

  fun _is_begin_quote(value : String box) : Bool =>
    try
      if value(0)? == '"' then true else false end
    else
      false
    end

  fun _is_end_quote(value : String box) : Bool =>
    """ Return true if string ends with '"' but not with '""' """
    try
      if value(value.size() - 1)? != '"' then return false end
    else
      return false
    end
    try
      if value(value.size() - 2)? == '"' then return false end
    else
      return true
    end
    true


actor Main
  new create(env: Env) =>
    env.out.print("Pony CSV reader")
    try
      let fileName = env.args(1)?
      env.out.print("Read file " + fileName)
      let filePath = FilePath(env.root as AmbientAuth, fileName)?
      try
        var reader = CsvReader.fromFile(filePath where with_title = true)?
        reader.dump(env.out)
        for title in reader.title().values() do
          env.out.print(title)
        end
      else
        env.out.print("Cannot read file")
      end

      try
        let invar = "Maman\nBateaux"
        var reader = CsvReader.fromBytes(invar.array())?
       reader.dump(env.out)
      end
    else
      env.out.print("Please provide a csv file as argument")
    end

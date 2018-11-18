use "files"


trait Reader
  fun ref lines(): Iterator[String]


class FileReader is Reader
  var _file: File

  new create(file: File) =>
    _file = file

  fun ref lines() : Iterator[String] =>
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

  fun ref next() : String =>
    let pos1 = _position
    let pos2 = _next_new_line()
    _position = pos2 + 1
    String.from_array(_bytes.trim(pos1, pos2))

  fun ref lines(): Iterator[String] =>
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

  new readFile(filePath: FilePath) ? =>
    match OpenFile(filePath)
    | let file: File =>
      _reader = FileReader(file)
    else
      error
    end

  new readBytes(data: Array[U8 val] val) =>
    _reader = BytesReader(data)

  fun ref dump(out: OutStream) =>
    for line in _reader.lines() do
      out.print("#" + line + "#")
    end


actor Main
  new create(env: Env) =>
    env.out.print("Pony CSV reader")
    try
      let fileName = env.args(1)?
      env.out.print("Read file " + fileName)
      let filePath = FilePath(env.root as AmbientAuth, fileName)?
      try
        var reader = CsvReader.readFile(filePath)?
        reader.dump(env.out)
      else
        env.out.print("Cannot read file")
      end

      let invar = "Maman\nBateaux"
      var reader = CsvReader.readBytes(invar.array())
      reader.dump(env.out)
    else
      env.out.print("Please provide a csv file as argument")
    end

use "files"


trait Reader
  fun ref readLine(): String ? => error


class FileReader is Reader
  var _file: File
  var _lines: FileLines

  new create(file: File) =>
    _file = file
    _lines = FileLines(file)

  fun ref readLine(): String ? =>
    _lines.next()?


class CsvReader
  var _reader : Reader

  new readFile(filePath: FilePath) ? =>
    match OpenFile(filePath)
    | let file: File =>
      _reader = FileReader(file)
    else
      error
    end

  fun ref dump(out: OutStream) =>
    while (true) do
      try
        out.print(_reader.readLine()?)
      else
        break
      end
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
    else
      env.out.print("Please provide a csv file as argument")
    end

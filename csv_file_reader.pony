use "files"

class _FileReader is _Reader
  var _file: File

  new create(file: File) =>
    _file = file

  fun ref lines() : Iterator[String] ref =>
    _file.seek_start(0)
    FileLines(_file)



class _BytesReader is (_Reader & Iterator[String])
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

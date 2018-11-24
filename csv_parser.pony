
primitive _CsvParser
  fun parse_next_line(
    lines : Iterator[String] ref,
    delim : String val)
    : Array[String] iso^ ?
  =>
    var result = recover Array[String] end
    var previous : String = ""
    repeat 
      (let res,  previous) = _parse_line(lines.next()?, delim, previous)
      if (result.size() == 0) and (previous.size() == 0) then
        result = consume res
      else
        let res_readable : Array[String] val = consume res
        for v in res_readable.values() do result.push(v) end
      end
    until previous.size() == 0 end
    consume result

  fun _parse_line(
	  line : String val,
	  delim : String val,
    prev : String val)
	  : (Array[String] iso^, String val)
  =>
    let result = recover Array[String] end
    var previous = prev

    for value in line.split_by(delim).values() do
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
          if _is_end_quote(value) or (value == "\"\"") then
            result.push(_unescape_quotes(value.trim(1, value.size() - 1)))
          else
            previous = value.trim(1)
          end
        else
          result.push(value)
        end
      end
    end
    if previous.size() > 0 then previous = previous + "\n" end
    (consume result, previous)

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
    """
    Return true if string ends with '"' but not with '""'
    ie, count the number of '"' at the end of the string
    """
    var count : USize = 0
    var index = value.size() - 1
    try
      while (index >= 0) do
        let c = value(index)?
        if c == '"' then count = count + 1 else break end
        index = index - 1
      end
      return (count % 2) == 1
    else
      return false
    end

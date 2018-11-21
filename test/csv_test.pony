use "collections/persistent"
use "ponytest"
use "package:.."


actor Main is TestList
  new create(env : Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test : PonyTest) =>
    test(_TestParseLineSimple)
    test(_TestParseLineQuotes)
    test(_TestParseMultiLineQuotes)
    test(_TestLines)
    test(_TestLinesWithTitle)
    test(_TestLinesMap)
    test(_TestAllLines)
    test(_TestAllLinesMap)


primitive TestUtil
  fun fields_eq(a : Array[String] box, b : Array[String] box) : Bool ? =>
    if a.size() != b.size() then
      return false
    end
    var i : USize = 0
    for va in a.values() do
      let vb = b(i)?
      if va != vb then return false end
      i = i + 1
    end
    true

  fun assert_fields_eq(
    h : TestHelper,
    a : Array[String] box,
    b : Array[String] box) ?
  =>
    let res = fields_eq(a, b)?
    h.log("compare: " + ";".join(a.values()) + " with " + ";".join(b.values()))
    h.assert_true(res)
    h.log("compare ok")

  fun assert_map_eq(
    h : TestHelper,
    a : Map[String, String] val,
    b : Array[(String val, String val)] box) ?
  =>
    for k in a.keys() do
      h.log("key found: " + k)
    end
    for (k, v) in b.values() do
      try
        let r = a(k)?
        h.log("check " + k + " = " + v + " => " + r)
        h.assert_true(r == v)
      else
        h.log("cannot get key " + k)
        error
      end
    end


class iso _TestParseLineSimple is UnitTest
  fun name() : String => "Parse a simple line"

  fun apply(h : TestHelper) ? =>
    let input = "One;Line;Titles"
    let reader = CsvReader.from_bytes(input where with_title = true)
    let titles = reader.title()
    TestUtil.assert_fields_eq(h, titles, ["One"; "Line"; "Titles"])?


class iso _TestParseLineQuotes is UnitTest
  fun name() : String => "Parse a line with quotes"

  fun apply(h : TestHelper) ? =>
    let input = "One;\"Line\";\"Titles \"\"more\"\" for us\""
    let reader = CsvReader.from_bytes(input where with_title = true)
    let titles = reader.title()
    TestUtil.assert_fields_eq(h, titles,
      ["One"; "Line"; "Titles \"more\" for us"])?


class iso _TestParseMultiLineQuotes is UnitTest
  fun name() : String => "Parse a line with quotes on multi lines"

  fun apply(h : TestHelper) ? =>
    let input = "One;\"Line\nand one other\";\"Titles\nof books \"\"more\"\" for us\""
    let reader = CsvReader.from_bytes(input where with_title = true)
    let titles = reader.title()
    TestUtil.assert_fields_eq(h, titles,
      ["One"; "Line\nand one other"; "Titles\nof books \"more\" for us"])?


class iso _TestLines is UnitTest
  fun name() : String => "Get several lines as string array"

  fun apply(h : TestHelper) ? =>
    let input = """
coucou;help me; twice
second line;like;first one
"difficult
line";" ""Bob"" is watching us";finally
    """
    let lines = CsvReader.from_bytes(input where with_title = false).lines()
    TestUtil.assert_fields_eq(h, lines.next()?,
      ["coucou"; "help me"; " twice"])?
    TestUtil.assert_fields_eq(h, lines.next()?,
      ["second line"; "like"; "first one"])?
    TestUtil.assert_fields_eq(h, lines.next()?,
      ["difficult\nline"; " \"Bob\" is watching us"; "finally"])?
    h.assert_true(lines.has_next() == false)


class iso _TestLinesWithTitle is UnitTest
  fun name() : String => "Get several lines after title, as string array"

  fun apply(h : TestHelper) ? =>
    let input = """
one;title;line
coucou;help me; twice
second line;like;first one
    """
    let lines = CsvReader.from_bytes(input where with_title = true).lines()
    TestUtil.assert_fields_eq(h, lines.next()?,
      ["coucou"; "help me"; " twice"])?
    TestUtil.assert_fields_eq(h, lines.next()?,
      ["second line"; "like"; "first one"])?
    h.assert_true(lines.has_next() == false)


class iso _TestLinesMap is UnitTest
  fun name() : String => "Get several lines as map"

  fun apply(h : TestHelper) ? =>
    let input = """
name,address,city
Joe,8 bob street,Paris
Edith,"7 bis park ""Pony"" ",London
"""
    let csv = CsvReader.from_bytes(input where with_title = true, delim = ",")
    TestUtil.assert_fields_eq(h, csv.title(), ["name"; "address"; "city"])?
    let lines = csv.lines_map()
    TestUtil.assert_map_eq(h, lines.next()?,
      recover val [("name", "Joe"); ("address", "8 bob street"); ("city", "Paris")] end)?
    TestUtil.assert_map_eq(h, lines.next()?,
      recover val [("name", "Edith"); ("address", "7 bis park \"Pony\" "); ("city", "London")] end)?
    h.assert_true(not lines.has_next())


class iso _TestAllLines is UnitTest
  fun name() : String => "Get all lines without title"

  fun apply(h : TestHelper) ? =>
    let input = """
Beautiful:Forest:Hill
Nice:Pony:Beast
"""
    let csv = CsvReader.from_bytes(input where with_title = false, delim = ":")
    let all_lines = csv.all_lines()
    h.assert_true(all_lines.size() == 2)
    TestUtil.assert_fields_eq(h, all_lines(0)?, ["Beautiful"; "Forest"; "Hill"])?
    TestUtil.assert_fields_eq(h, all_lines(1)?, ["Nice"; "Pony"; "Beast"])?


class iso _TestAllLinesMap is UnitTest
  fun name() : String => "Get all lines as maps"

  fun apply(h : TestHelper) ? =>
    let input = """
name,address,city
Joe,8 bob street,Paris
Edith,"7 bis park ""Pony"" ",London
"""
    let csv = CsvReader.from_bytes(input where with_title = true, delim = ",")
    let all_lines = csv.all_lines_map()

    TestUtil.assert_map_eq(h, all_lines(0)?,
      recover val [("name", "Joe"); ("address", "8 bob street"); ("city", "Paris")] end)?
    TestUtil.assert_map_eq(h, all_lines(1)?,
      recover val [("name", "Edith"); ("address", "7 bis park \"Pony\" "); ("city", "London")] end)?

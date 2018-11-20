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


class iso _TestParseLineSimple is UnitTest
  fun name() : String => "Parse a simple line"

  fun apply(h : TestHelper) ? =>
    let input = "One;Line;Titles"
    let reader = CsvReader.fromBytes(input where with_title = true)
    let titles = reader.title()
    h.assert_true(TestUtil.fields_eq(titles, ["One"; "Line"; "Titles"])?)


class iso _TestParseLineQuotes is UnitTest
  fun name() : String => "Parse a line with quotes"

  fun apply(h : TestHelper) ? =>
    let input = "One;\"Line\";\"Titles \"\"more\"\" for us\""
    let reader = CsvReader.fromBytes(input where with_title = true)
    let titles = reader.title()
    h.assert_true(TestUtil.fields_eq(titles,
      ["One"; "Line"; "Titles \"more\" for us"])?)


class iso _TestParseMultiLineQuotes is UnitTest
  fun name() : String => "Parse a line with quotes on multi lines"

  fun apply(h : TestHelper) ? =>
    let input = "One;\"Line\nand one other\";\"Titles\nof books \"\"more\"\" for us\""
    let reader = CsvReader.fromBytes(input where with_title = true)
    let titles = reader.title()
    for v in titles.values() do h.log(v) end
    h.assert_true(TestUtil.fields_eq(titles,
      ["One"; "Line\nand one other"; "Titles\nof books \"more\" for us"])?)

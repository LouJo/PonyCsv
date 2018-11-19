use "ponytest"

actor Main is TestList
  new create(env : Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test : PonyTest) =>
    test(_TestParseLineSimple)


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

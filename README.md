# Pony CSV
### CSV reader and parser for pony language

Read and parse csv files with respect of RFC 4180 (https://tools.ietf.org/html/rfc4180)

Created as a module for pony : https://www.ponylang.io/

## Usage

Creating a CSV reader from a file, with first line as title and "," as separator
```pony
  let file_path = FilePath(env.root as AmbientAuth, fileName)?
  var csv = CsvReader.from_file(file_path where with_title = true, delim=",")?
```

Using following file for exemples:

```
    name;birth;city
    Bob;46;Paris
    Amandine;21;London
    Judith;32;Amsterdam
```

Get csv lines with an iterator. File will be read gradually:
```pony
  var csv = CsvReader.from_file(file_path where with_title = false, delim=";")?
  let lines = csv.lines()
  for line in lines do
    // ["Bob"; "46", "Paris"]
    // ["Amandine"; "21", "London"]
    // ["Judith"; "63", "Amsterdam"]
  end
```

Get csv lines as maps, using titles as keys. File will be read gradually:
```pony
  var csv = CsvReader.from_file(file_path where with_title = true, delim=";")?
  let lines = csv.lines_map()
  for line in lines do
    // ("name" => "Bob"; "birth" => "46"; "city" => "Paris")
    // ("name" => "Amandine"; "birth" => "21"; "city" => "London")
    // ("name" => "Judith"; "birth" => "63"; "city" => "Amsterdam")
  end
```

Get all lines at once in an array:
```pony
  var csv = CsvReader.from_file(file_path where with_title = true, delim=";")?
  let all_lines = csv.all_lines()
  // [["Bob"; "46"; "Paris"]; ["Amandine"; "21"; "London"]; ["nJudith"; "63", "Amsterdam"]]
```

Get the second column as array of values:
```pony
  var csv = CsvReader.from_file(file_path where with_title = false, delim=";")?
  var column = csv.column(1)?
  // ["birth"; "46"; "21"; "32"]
```

Get all columns at once in an array:
```pony
  var csv = CsvReader.from_file(file_path where with_title = false, delim=";")?
  var all_cols = csv.all_columns()?
  // [["Bob"; "Amandine"; "Judith"]; ["46"; "21"; "63"]; ["Paris"; "London"; "Amsterdam"]]
```



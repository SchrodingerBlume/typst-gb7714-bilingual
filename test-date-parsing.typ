// 测试日期解析功能

#import "src/core/date-parser.typ": parse-date, format-parsed-date
#import "src/core/date-handler.typ": extract-year-info, get-display-date, has-date, is-date-range

#set page(width: 16cm, height: auto, margin: 1cm)
#set text(font: "Noto Serif CJK SC")

= 日期解析测试

== 1. 基础日期解析测试

#let test-cases = (
  ("2001-05-06", "单个完整日期"),
  ("2001-05", "年-月格式"),
  ("2001", "仅年份"),
  ("2001-05-06/2001-08-01", "日期范围（完整）"),
  ("2020/2021", "年份范围"),
  ("2001-5-6", "月日不足两位（应失败）"),
  ("01-05-06", "年份不足四位（应失败）"),
  ("2001-13-01", "月份超出范围（应失败）"),
  ("2001-05-32", "日期超出范围（应失败）"),
  ("1881(清光绪七年)", "非标准格式（应失败）"),
)

#table(
  columns: (auto, 1fr, 1fr, 1fr),
  [*输入*], [*说明*], [*解析结果*], [*格式化输出*],
  ..for (input, desc) in test-cases {
    let parsed = parse-date(input)
    let result = if parsed == none {
      text(red)[失败]
    } else {
      text(green)[成功]
    }
    let formatted = if parsed != none {
      format-parsed-date(parsed)
    } else {
      "-"
    }
    (
      raw(input),
      desc,
      result,
      formatted,
    )
  }
)

== 2. 字段提取测试

#let field-test-cases = (
  (
    "有date字段（标准格式）",
    (fields: (date: "2001-05-06")),
  ),
  (
    "有date字段（范围）",
    (fields: (date: "2001-05-06/2001-08-01")),
  ),
  (
    "有year字段（仅年份）",
    (fields: (year: "2020")),
  ),
  (
    "有year字段（非标准格式）",
    (fields: (year: "1881(清光绪七年)")),
  ),
  (
    "date和year都有",
    (fields: (date: "2020-01-01", year: "2020")),
  ),
  (
    "date无法解析，year可用",
    (fields: (date: "2020-1-1", year: "2020")),
  ),
  (
    "都没有",
    (fields: (:)),
  ),
)

#table(
  columns: (1fr, auto, auto, auto),
  [*测试用例*], [*year-str*], [*来源*], [*是否为范围*],
  ..for (desc, entry) in field-test-cases {
    let info = extract-year-info(entry, year-suffix: "")
    (
      desc,
      raw(info.year-str),
      raw(info.source),
      str(is-date-range(info)),
    )
  }
)

== 3. 显示格式测试

#let entry-full = (fields: (date: "2001-05-06/2001-08-01"))
#let info-full = extract-year-info(entry-full)

#let entry-year = (fields: (year: "2020"))
#let info-year = extract-year-info(entry-year)

#let entry-raw = (fields: (year: "1881(清光绪七年)"))
#let info-raw = extract-year-info(entry-raw)

#table(
  columns: (1fr, auto, auto),
  [*条目*], [*仅年份*], [*完整日期*],
  [date: 2001-05-06/2001-08-01],
  get-display-date(info-full, only-year: true),
  get-display-date(info-full, full-date: true),

  [year: 2020],
  get-display-date(info-year, only-year: true),
  get-display-date(info-year, full-date: true),

  [year: 1881(清光绪七年)],
  get-display-date(info-raw, only-year: true),
  get-display-date(info-raw, full-date: true),
)

== 4. 消歧后缀测试

#let entry = (fields: (year: "2020"))
#let info-a = extract-year-info(entry, year-suffix: "a")
#let info-b = extract-year-info(entry, year-suffix: "b")

同一年份的两篇文献：
- 第一篇：#get-display-date(info-a)
- 第二篇：#get-display-date(info-b)

== 5. 详细解析结果示例

#let show-parsed(input) = {
  let parsed = parse-date(input)
  if parsed == none {
    text(red)[无法解析]
  } else {
    table(
      columns: 2,
      [year], parsed.year,
      [month], str(parsed.month),
      [day], str(parsed.day),
      [endyear], str(parsed.endyear),
      [endmonth], str(parsed.endmonth),
      [endday], str(parsed.endday),
    )
  }
}

*输入：* `2001-05-06/2001-08-01`

#show-parsed("2001-05-06/2001-08-01")

*输入：* `2020`

#show-parsed("2020")

// GB/T 7714 双语参考文献系统 - 日期解析器
// 实现 biblatex-gb7714 的日期解析规则

// 验证字符串是否为纯数字
#let is-numeric(s) = {
  if s == "" { return false }
  for c in s.clusters() {
    if c not in "0123456789" {
      return false
    }
  }
  true
}

// 解析单个日期部分 (yyyy-mm-dd 或 yyyy-mm 或 yyyy)
#let parse-single-date(date-str) = {
  if date-str == "" or date-str == none {
    return none
  }

  let s = str(date-str).trim()
  let components = s.split("-")

  if components.len() < 1 or components.len() > 3 {
    return none
  }

  // 验证年份（必须是4位数字）
  let year = components.at(0)
  if year.len() != 4 or not is-numeric(year) {
    return none
  }

  let month = none
  let day = none

  // 验证月份（如果有，必须是2位数字，01-12）
  if components.len() >= 2 {
    month = components.at(1)
    if month.len() != 2 or not is-numeric(month) {
      return none
    }
    let m = int(month)
    if m < 1 or m > 12 {
      return none
    }
  }

  // 验证日期（如果有，必须是2位数字，01-31）
  if components.len() >= 3 {
    day = components.at(2)
    if day.len() != 2 or not is-numeric(day) {
      return none
    }
    let d = int(day)
    if d < 1 or d > 31 {
      return none
    }
  }

  (year: year, month: month, day: day)
}

/// 解析 ISO 格式日期字符串
/// 支持格式：
/// - yyyy (仅年份)
/// - yyyy-mm (年-月)
/// - yyyy-mm-dd (年-月-日)
/// - yyyy-mm-dd/yyyy-mm-dd (日期范围)
///
/// 返回：解析成功返回包含 year/month/day/endyear/endmonth/endday 的字典，失败返回 none
#let parse-date(date-str) = {
  if date-str == "" or date-str == none {
    return none
  }

  let s = str(date-str).trim()

  // 检查是否包含起止日期分隔符 /
  let parts = s.split("/")

  if parts.len() > 2 {
    return none  // 格式错误：不能有多个 /
  }

  // 解析起始日期
  let start = parse-single-date(parts.at(0))
  if start == none {
    return none
  }

  // 解析结束日期（如果有）
  let end = none
  if parts.len() == 2 {
    end = parse-single-date(parts.at(1))
    if end == none {
      return none  // 有第二部分但解析失败
    }
  }

  // 返回解析结果
  (
    year: start.year,
    month: start.month,
    day: start.day,
    endyear: if end != none { end.year } else { none },
    endmonth: if end != none { end.month } else { none },
    endday: if end != none { end.day } else { none },
  )
}

/// 格式化解析后的日期用于显示
/// 输入：parse-date() 返回的字典
/// 输出：格式化后的日期字符串
#let format-parsed-date(parsed) = {
  if parsed == none {
    return ""
  }

  let start = parsed.year
  if parsed.month != none {
    start += "-" + parsed.month
  }
  if parsed.day != none {
    start += "-" + parsed.day
  }

  // 如果有结束日期，添加范围
  if parsed.endyear != none {
    let end = parsed.endyear
    if parsed.endmonth != none {
      end += "-" + parsed.endmonth
    }
    if parsed.endday != none {
      end += "-" + parsed.endday
    }
    return start + "/" + end
  }

  start
}

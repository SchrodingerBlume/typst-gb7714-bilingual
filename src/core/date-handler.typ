// GB/T 7714 双语参考文献系统 - 日期字段处理器
// 实现 biblatex-gb7714 的 year/date 字段处理规则

#import "date-parser.typ": parse-date, format-parsed-date

/// 统一提取和处理 year/date 字段
/// 按 biblatex-gb7714 的规则处理：
/// 1. 优先解析 date 字段
/// 2. 如果 date 不存在或无法解析，尝试解析 year 字段
/// 3. 如果 year 也无法解析，则原样保留 year（支持 "1881(清光绪七年)" 等格式）
///
/// 参数：
/// - entry: 文献条目
/// - year-suffix: 年份后缀（用于消歧，如 "a", "b"）
///
/// 返回：
/// - year-str: 显示用的年份字符串（已包含后缀）
/// - parsed: 解析后的日期结构（如果解析成功），否则为 none
/// - raw-year: 原始的 year 字段值
/// - source: 日期来源 ("date", "year", 或 "none")
#let extract-year-info(entry, year-suffix: "") = {
  let f = entry.at("fields", default: (:))
  let date-field = f.at("date", default: none)
  let year-field = f.at("year", default: none)

  // 优先级1：如果有 date 字段，尝试解析
  if date-field != none and str(date-field) != "" {
    let parsed = parse-date(date-field)
    if parsed != none {
      // 解析成功，返回解析后的年份
      return (
        year-str: parsed.year + year-suffix,
        parsed: parsed,
        raw-year: year-field,
        source: "date",
      )
    }
    // date 解析失败，继续尝试 year
  }

  // 优先级2：如果有 year 字段，先尝试作为 date 解析
  if year-field != none and str(year-field) != "" {
    let parsed = parse-date(year-field)
    if parsed != none {
      // year 可以解析为 date
      return (
        year-str: parsed.year + year-suffix,
        parsed: parsed,
        raw-year: year-field,
        source: "year-parsed",
      )
    } else {
      // year 无法解析为 date，原样返回
      // 这种情况支持 "1881(清光绪七年)" 等格式
      return (
        year-str: str(year-field) + year-suffix,
        parsed: none,
        raw-year: year-field,
        source: "year-raw",
      )
    }
  }

  // 没有日期信息
  return (
    year-str: year-suffix,  // 只有后缀（如果有）
    parsed: none,
    raw-year: none,
    source: "none",
  )
}

/// 获取显示用的年份或日期字符串
/// 参数：
/// - year-info: extract-year-info() 返回的结构
/// - full-date: 是否显示完整日期（包括月日），默认 false
/// - only-year: 是否只显示年份（忽略月日），默认 false
///
/// 返回：格式化后的日期/年份字符串
#let get-display-date(year-info, full-date: false, only-year: false) = {
  // 如果要求只显示年份，或没有解析结果，返回 year-str
  if only-year or year-info.parsed == none {
    return year-info.year-str
  }

  // 如果要求显示完整日期，返回格式化后的完整日期
  if full-date {
    return format-parsed-date(year-info.parsed)
  }

  // 默认只显示年份
  year-info.year-str
}

/// 检查是否有有效的日期信息
#let has-date(year-info) = {
  year-info.year-str != "" and year-info.source != "none"
}

/// 获取月份（如果有）
#let get-month(year-info) = {
  if year-info.parsed == none {
    return none
  }
  year-info.parsed.month
}

/// 获取日（如果有）
#let get-day(year-info) = {
  if year-info.parsed == none {
    return none
  }
  year-info.parsed.day
}

/// 检查是否为日期范围
#let is-date-range(year-info) = {
  if year-info.parsed == none {
    return false
  }
  year-info.parsed.endyear != none
}

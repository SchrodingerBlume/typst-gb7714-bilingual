// GB/T 7714 双语参考文献系统 - 期刊文章渲染器

#import "../authors.typ": format-authors
#import "../types.typ": render-type-id
#import "../versions/mod.typ": get-punctuation
#import "../core/utils.typ": build-journal-info, render-base
#import "../core/date-handler.typ": extract-year-info, get-display-date

/// 期刊文章渲染（也用于报纸、连续出版物）
/// 格式：作者. 题名[J]. 刊名，年，卷（期）：页码.
/// 报纸格式：作者. 题名[N]. 报纸名，年：页码.
#let render-article(
  entry,
  lang,
  year-suffix: "",
  style: "numeric",
  version: "2025",
  config: (show-url: true, show-doi: true, show-accessed: true),
) = {
  let f = entry.fields
  let entry-type = lower(entry.entry_type)

  let authors = format-authors(entry.parsed_names, lang, version: version)
  let title = f.at("title", default: "")
  let journal = f.at("journal", default: f.at("journaltitle", default: ""))

  // 使用新的日期处理机制
  let year-info = extract-year-info(entry, year-suffix: year-suffix)
  let year = year-info.year-str

  // 报纸需要显示完整日期（年-月-日），期刊只显示年份
  let is-newspaper = entry-type == "newspaper"
  let publication-date = if is-newspaper {
    get-display-date(year-info, full-date: true)
  } else {
    year
  }

  let volume = f.at("volume", default: "")
  let number = f.at("number", default: f.at("issue", default: ""))
  let pages = f.at("pages", default: "").replace("--", "-")
  let doi = f.at("doi", default: "")
  let url = f.at("url", default: "")
  let mark = f.at("_resolved_mark", default: none)
  let medium = f.at("_resolved_medium", default: none)

  // 使用实际条目类型（newspaper → [N]，periodical → [J]，article → [J]）
  let type-id = render-type-id(
    entry-type,
    has-url: url != "" or doi != "",
    version: version,
    mark: mark,
    medium: medium,
  )
  let punct = get-punctuation(version, lang)

  render-base(
    entry,
    authors,
    year,
    punct,
    style,
    config,
    year-in-pub => {
      let parts = ()
      parts.push(title + type-id)

      // 报纸使用完整日期，期刊使用年份
      let date-to-display = if is-newspaper { publication-date } else { year }

      let pub-info = build-journal-info(
        journal,
        date-to-display,
        volume,
        number,
        pages,
        punct,
        include-year: if style == "author-date" { year-in-pub } else { true },
      )
      if pub-info != "" {
        parts.push(pub-info)
      }
      parts
    },
  )
}

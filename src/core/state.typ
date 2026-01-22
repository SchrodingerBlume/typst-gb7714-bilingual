// GB/T 7714 双语参考文献系统 - 状态管理模块

#import "date-handler.typ": extract-year-info

// ============================================================
//                      状态定义
// ============================================================

#let _bib-data = state("gb7714-bib-data", (:))
#let _style = state("gb7714-style", "numeric")
#let _version = state("gb7714-version", "2025")  // "2015" 或 "2025"

// 显示配置
#let _config = state("gb7714-config", (
  show-url: true, // 是否显示 URL
  show-doi: true, // 是否显示 DOI
  show-accessed: true, // 是否显示访问日期
  enable-year-suffix: true, // 是否启用年份消歧后缀（author-date 模式）
  year-suffix-sort: "citation-order", // 消歧后缀排序方式："citation-order" (引用顺序) 或 "title" (标题字母序)
))

// 用于标记引用的辅助函数（使用 metadata + query 模式）
#let _cite-marker(key) = [#metadata(key)<gb7714-cite>]

// 从文档中收集所有引用并建立顺序映射
#let _collect-citations() = {
  let cites = query(<gb7714-cite>)
  let seen = (:)
  let order = 0
  for c in cites {
    let key = c.value
    if key not in seen {
      order += 1
      seen.insert(key, order)
    }
  }
  seen
}

// 计算年份后缀（用于 author-date 模式消歧）
// 返回 key -> suffix 的映射，如 ("smith2020a": "a", "smith2020b": "b")
#let _compute-year-suffixes(bib, citations, config: (enable-year-suffix: true, year-suffix-sort: "citation-order")) = {
  // 如果禁用消歧，直接返回空映射
  if not config.at("enable-year-suffix", default: true) {
    return (:)
  }

  let sort-mode = config.at("year-suffix-sort", default: "citation-order")

  // 按 (第一作者姓, 年份) 分组
  let groups = (:)
  for (key, citation-order) in citations.pairs() {
    let entry = bib.at(key, default: none)
    if entry == none { continue }

    let names = entry.parsed_names.at("author", default: ())
    let first-author = if names.len() > 0 {
      names.first().at("family", default: "")
    } else { "" }

    // 使用 extract-year-info 提取年份，支持 date/year 字段
    let year-info = extract-year-info(entry, year-suffix: "")
    let year = if year-info.parsed != none {
      // 如果解析成功，使用解析后的年份
      year-info.parsed.year
    } else {
      // 如果无法解析（如 "1881(清光绪七年)"），使用原始 year-str
      year-info.year-str
    }

    let group-key = first-author + "|" + str(year)

    if group-key not in groups {
      groups.insert(group-key, ())
    }
    groups
      .at(group-key)
      .push((
        key: key,
        title: entry.fields.at("title", default: ""),
        order: citation-order,  // 保存引用顺序
      ))
  }

  // 为每组分配后缀
  let suffixes = (:)
  for (group-key, items) in groups.pairs() {
    if items.len() > 1 {
      // 根据配置选择排序方式
      let sorted-items = if sort-mode == "citation-order" {
        // 按引用顺序排序（默认）
        items.sorted(key: it => it.order)
      } else {
        // 按标题字母序排序
        items.sorted(key: it => it.title)
      }

      let suffix-chars = "abcdefghijklmnopqrstuvwxyz"
      for (i, item) in sorted-items.enumerate() {
        if i < suffix-chars.len() {
          suffixes.insert(item.key, suffix-chars.at(i))
        }
      }
    }
  }
  suffixes
}

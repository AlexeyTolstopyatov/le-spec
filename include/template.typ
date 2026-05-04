#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 2.5cm),
  numbering: "1",
  header: context [
    #set text(size: 8pt, fill: luma(140))
    #align(center)[
      16/32-bit Microsoft Linear Executable and Windows Virtual Device Driver (V) Model
    ]
  ],
  footer: context [
    #set text(size: 8pt, fill: luma(140))
    #align(center)[
      #counter(page).display()
    ]
  ],
)

#set text(font: "Libertinus Serif", size: 11pt)
#set heading(numbering: "1.1")
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  it
}

// Code blocks
#show raw.where(block: true): it => {
  set text(font: "Libertinus Mono", size: 9pt)
  block(
    inset: 8pt,
    radius: 4pt,
    it
  )
}

// Table of contents
#outline(
  title: [Table of Contents],
  depth: 3,
)
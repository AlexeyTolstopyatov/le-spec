#set document(
  title: "16/32-bit Linear Executable Module Format 0:32 \n and\n Windows Virtual Device Driver (VxD) Model",

  author: "Alexey Tolstopyatov<atolstopyatov2017@vk.com>",
  date: auto,
)
// Declare header before page settings will be applied
// It helps to hide first page# and define start of document 
#text(font: "Times New Roman", size: 24pt)[
  #align(center)[
    #title()
    #line()
    _Revision 1.0_
  ]
]
// Declare page view settings:
// Paper: A4,
// Fields: Normal
// Content: Times New Roman 14pt
#set page(
  paper: "a4",
  margin: (x: 2.0cm, y: 2.0cm),
  numbering: "1",
  header: context [
    #set par(leading: 0.6em)
    #set text(size: 12pt, fill: luma(140), font: "Times New Roman")
    #align(center)[
      16/32-bit Microsoft Linear Executable 0.32 and Windows Virtual Device Driver (VxD) Model
    ]
  ],
  footer: context [
    #set par(leading: 0.65em)
    #set text(size: 12pt, fill: luma(140))
    #align(center)[
      #counter(page).display()
    ]
  ],
)
// Code blocks and inline code will be Fira Code 12pt
// Padding size between strings: 0.65em
#set text(font: "Times New Roman", size: 14pt)
#show raw: it => {
  set text(font: "Fira Mono", size: 12pt)
  it
}
#let first-par-after-heading = counter("first-par")
//#first-par-after-heading.update(1)
#show heading: it => {
  first-par-after-heading.update(1)
  pad(1.5em)[#it]
}
#show raw.where(block: true): it => {
  set par(leading: 0.65em)
  block(
    //fill: luma(245),
    //stroke: 0.5pt + luma(200),
    inset: 8pt,
    radius: 2pt,
    it,
  )
}
//
// ┬ ┴ ┼
//
#set par(leading: 1.0em, justify: true, first-line-indent: 1.25cm)

#outline(title: [Contents], depth: 3)
#pagebreak()
#include "chapters/chapter0_introduction.typ"
#include "chapters/chapter1_1_program_header.typ"
#include "chapters/chapter1_2_memory_model.typ"
#include "chapters/chapter1_3_runtime.typ"
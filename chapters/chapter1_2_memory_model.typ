#import "../template.typ" as util

== Module Pages

Module pages concept defines the special "physical sections" of program text and data.
At the moment of format revision `0:32` by IBM and Microsoft, module pages records are represent an array of 32-bit records.

On the next listing presented a single module page record.
#figure(
```
┌─────┬─────┬─────┬─────┐
│    Long page#   │Flags│   
└─────┴─────┴─────┴─────┘
└────────┬────────┘     │
       24-bit     └──┬──┘
                   8-bit
```,
caption: "Module page record layout"
) <le-mpage-record>

Numbering of module pages starts from one.
Count of module pages contains in the executable header in the `e32_mpages` field. 
For each module page except last page the `e32_pagesize` is valid.
Last module page have size which equal `e32_lastpagesize` value.

#figure(
  rect()[
    #set par(leading: 0.65em)
    #set list(indent: 1cm)
    #set align(left)
    After the linkage the Module pages always aligned by the paragraph (`0x10`).
    To compute file offset to the page start, make sure that you know
     - Long Page index;
     - Page is vaid (`Flags` set to zero);
     - Page size (`e32_pagesize`);
     - Offset to enumerated datapages (`e32_datapage`);
    #align(center)[
        ```
        page_offset := e32_datapage + (page# - 1) * e32_pagesize;
        ```
    ]
  ]
)


Per-page attributes or `Flags` field presented in the previous listing.

#figure(
  table(
    columns: (auto, auto),
    align: (center, left, left),
    inset: 6pt,
    stroke: 0.5pt,
    table.header(
      [*Byte*], [*Description*]
    ),
    [0x00], [Valid Physical Page],
    [0x01], [Iterated page],
    [0x02], [Invalid page],
    [0x03], [Zeroed page],
    [0x04], [Pages range]
  ),
  caption: [Per-page attributes]
) <tbl-module-flags-high>

== Object Table

From the point of view of file, objects in the linear executable represents a reserved range of module pages where some text or data could be placed.

To find out which module pages reserved for which object, 
the file offset of the object table `e32_objtab` and `e32_objcnt` are read from the program header and entire table is reviewed.

Objects table is just an array of object records. Object record presented next

#figure(
```
      32-bit field
┌───────────┴───────────┐
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐ ┐
│        Object VA      │    Object Base VA     │ ├ 2 fields
├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤ ┘
│      Object Flags     │      Object Page#     │   
├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
│   # Of Module Pages   │        Reserved       │   
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘

```,
    caption: "Object record layout"
) <le-object-record>

On this listing the `DWORD` fields ordering starts from upper left
and reads till the least right field at the bottom.

Per-Object flags is a bitmask field which may contain bits which defined in the next table

#figure(
  table(
    columns: (auto, auto),
    align: (center, left),
    inset: 6pt,
    stroke: 0.5pt,
    table.header(
      [*Word*], [*Description*]
    ),
    [0x0001], [Readable Object],
    [0x0002], [Writable Object],
    [0x0004], [Executable Object],
    [0x0008], [Resource Object],
    [0x0010], [Object is discardable],
    [0x0020], [Object is shared],
    [0x0040], [Object has preload pages],
    [0x0080], [Object uses invalid pages],
  ),
  caption: [Object flags (low byte)]
) <tbl-obj-low>

#figure(
    table(
        columns: (auto, auto),
        align: (center, left),
        inset: 6pt,
        stroke: 0.5pt,
        table.header(
            [*Word*], [*Description*]
        ),    
        [0x0100], [Object is permanent and swappable],
        [0x0200], [Object is permanent and resident],
        [0x0300], [Object is resident and contiguous],
        [0x0400], [Object is permanent and long locable],
        [0x0600], [Object is nonpermanent -- should be],
        [0x0700], [Object type-mask],
        [0x1000], [16:16 alias required (80x86 specific)],
        [0x2000], [Big bit setting (80x86 specific)],
        [0x4000], [Object is conforming for code],
        [0x8000], [Object I/O Privileges],
    ),
    caption: [Object flags (High byte)]
) <tbl-obj-high>

== Resource Table

The resource table is an array of resource table entries. 
Each resource table entry contains a `type` and `name`. 
These entries are used to locate resource objects contained in the Object table. 

#figure(
```
┌─────┬─────┬─────┬─────┐ ┐
│    Type   │    Name   │ ├ 2 fields
├─────┼─────┼─────┼─────┤ ┘
│  Resource block size  │
├─────┼─────┼─────┼─────┼─────┬─────┐
│  Object#  │ Offset within object  │
└─────┴─────┴─────┴─────┴─────┴─────┘
│           └───────────┬───────────┘
└─────┬─────┘         32-bit          
    16-bit
```, 
    caption: [Resource Table record]
)

The number of entries in the resource records is defined by the Resource Table 
Count located in the linear executable header. 
More than one resource may be contained within a 
single object. 
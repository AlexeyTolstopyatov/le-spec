#import "../template.typ" as util

#pagebreak()
#let number = context counter("first-par").display()

= Linear Executable File Layout

Same with the New Executable format, first bytes of file belong 
to the Mark Zbikowski executable header. 
After those header bytes the DOS compatible program image starts.
The field by the `0x3C` offset still hold an offset from the beginning of file to the next protected-mode executable image.

DOS 2.0 compatible part will skipped in this manual. 
First 2 bytes after `e_lfanew` long offset will be ASCII signature `[0x45, 0x4C]`.
It has not been experimentally confirmed that the byte order affects the signature, 
however, I allow different byte order. 
That's why, is better to check `LE` and `EL` ASCII signatures.

At the next page presented file layout (see Figure #number.1) 

#pagebreak()
#align(center)[
  ```
  ┌─────────────────────────┐
  │ MZ Header               │────+
  ├─────────────────────────┤    │ If e_lfarlc = 0x40 and  
  │ MZ relocations          │    │    e_lfanew not zero
  │ DOS executable image    │    │
  ├─────────────────────────┤    │ 
  │ LE executable header    <────+
  ├─────────────────────────┤      
  │ Import names table      │
  │ Resident names table    │
  ├─────────────────────────┤
  │ Fixup offsets           ────++
  ├─────────────────────────┤   ││ Offsets to the object 
  │ ...                     │   ││ fixup records tables
  │ Fixup records           <───│+
  │ Fixup records           <───+
  ├─────────────────────────┤   
  │ Memory Pages            ├──────────+
  │ Objects Table           │          │
  │ Objects Table           │          │
  │ ...                     │          │
  ├─────────────────────────┤ <────+   │  
  │ Memory Page #1          │      │<──+
  │ [Object #1]             │      │ Module pages
  ├─────────────────────────┤      │ of LE program module
  ├─────────────────────────┤      │      
  │ Memory Page #2          │      │ Might be iterated or
  │ [Object #1]             │      │ compressed at all. 
  ├─────────────────────────┤      │ 
  │ Memory Page #3          │      │ One object can be splitted
  │ [Object #2]             │      │ by some module pages
  ├─────────────────────────┤      │
  │ Memory Page #n          │      │
  │ [Resources Object#]     │      │
  ├─────────────────────────┤<─────+      
  │ Debug symbols (optional)│
  ├─────────────────────────┤
  │ Non-Resident names      │
  └─────────────────────────┘
  ```
  Figure #number.1 -- Linear executable file layout
]

#pagebreak()

Dispite the fact that `LE` format very similar with child -- `LX` format,
*don't apply `LX` module tables to `LE` module format!*

Since the IBM modification of linear executable module format,
DOS 2.0 compatible program might be removed from file. 
So and `*.EXE/DLL/SYS` files will contain only `LX` program part.

== Program Header

At the table #number.1 presented full map of linear executable header

#table(
  columns: (auto, auto, auto, auto),
  align: (right, center, left, left),
  inset: 6pt,
  stroke: 0.5pt,
  table.header(
    [*Offset*], [*Size*], [*Name*], [*Description*]
  ),
  [0x00], [2], [e32_magic], [Magic ASCII (0x454C)],
  [0x02], [1], [e32_border], [Byte ordering],
  [0x03], [1], [e32_worder], [Word ordering],
  [0x04], [4], [e32_level], [Format level (0 for initial version)],
  [0x08], [2], [e32_cpu], [CPU type],
  [0x0A], [2], [e32_os], [Operating system type],
  
  // Module identification
  [0x0C], [4], [e32_ver], [Module version number],
  [0x10], [4], [e32_mflags], [Module flags],
  [0x14], [4], [e32_mpages], [Number of pages in module],
  
  // Entry point
  [0x18], [4], [e32_startobj], [Object number for instruction pointer],
  [0x1C], [4], [e32_eip], [Extended instruction pointer],
  
  // Memory map
  [0x20], [4], [e32_stackobj], [Object number for stack pointer],
  [0x24], [4], [e32_esp], [Extended stack pointer (offset within object)],
  [0x28], [4], [e32_pagesize], [Page size in bytes (typically 4096)],
  [0x2C], [4], [e32_lastpagesize], [Size of last page in bytes],
  
  // Fixup section
  [0x30], [4], [e32_fixupsize], [Fixup section size in bytes],
  [0x34], [4], [e32_fixupsum], [Fixup section checksum],
  
  // Loader section
  [0x38], [4], [e32_ldrsize], [Loader section size in bytes],
  [0x3C], [4], [e32_ldrsum], [Loader section checksum],
  
  // Object table
  [0x40], [4], [e32_objtab], [Offset of object table from start of LE header],
  [0x44], [4], [e32_objcnt], [Number of objects in module],
  [0x48], [4], [e32_objmap], [Offset of object page map],
  [0x4C], [4], [e32_itermap], [Offset of object iterated data map],
  [0x50], [4], [e32_rsrctab], [Offset of resource table],
  [0x54], [4], [e32_rsrccnt], [Number of resource entries],
  
  // Exports
  [0x58], [4], [e32_restab], [Offset of resident name table],
  [0x5C], [4], [e32_enttab], [Offset of entry table],
  
  // Module directives
  [0x60], [4], [e32_dirtab], [Offset of module directive table],
  [0x64], [4], [e32_dircnt], [Number of module directives],
  
  // Fixup page table
  [0x68], [4], [e32_fpagetab], [Offset of fixup page table],
  [0x6C], [4], [e32_frectab], [Offset of fixup record table],
  
  // Import module name table
  [0x70], [4], [e32_impmod], [Offset of import module name table],
  [0x74], [4], [e32_impmodcnt], [Number of entries in import module name table],
  [0x78], [4], [e32_impproc], [Offset of import procedure name table],
  
  // Per-page checksum table
  [0x7C], [4], [e32_pagesum], [Offset of per-page checksum table],
  
  // Memory map
  [0x80], [4], [e32_datapage], [Offset of enumerated data pages],
  [0x84], [4], [e32_preload], [Number of preload pages],
  // Non-resident exports
  [0x88], [4], [e32_nrestab], [Offset of non-resident names table],
  [0x8C], [4], [e32_cbnrestab], [Size of non-resident name table in bytes],
  [0x90], [4], [e32_nressum], [Non-resident name table checksum],
  
  // Automatic data object
  [0x94], [4], [e32_autodata], [Object number for automatic data object],
  
  // Debug information
  [0x98], [4], [e32_debuginfo], [Offset of debugging information],
  [0x9C], [4], [e32_debuglen], [Length of debugging information in bytes],
  
  // Instance pages
  [0xA0], [4], [e32_instpreload], [Number of instance pages in preload section],
  [0xA4], [4], [e32_instdemand], [Number of instance pages in demand section],
  [0xA8], [4], [e32_heapsize], [Size of heap for 16-bit applications],
  
  // Reserved
  [0xAC], [24], [e32_res3], [Reserved bytes to pad structure to 196 bytes],
) <le-header>

Total size of `LE` header -- 196 bytes (or 0xC4). All offsets are from the start of the LE header.

Differences between `LE` and `LX` headers starts here already. 
Field by the `0x2C` offset from the beginning of header stores resident value of 
#util.code("size (in bytes) of last module page", "e32_lastpagesize") instead of #util.code("module pages alignment", "e32_pageshift") 

This difference is one of the key ones in the comparison. Further more. In the following sections, the layout of memory pages will be discussed, and this field will help. 

== Target CPU type

Some fields in the header describes module characteristics and 
stores them as enumerated values or bits in the bit mask. 


#figure(
  table(
    columns: (auto, auto),
    align: (center, left),
    inset: 6pt,
    stroke: 0.5pt,
    table.header(
      [*Value*], [*CPU Type*]
    ),
    [0x01], [Intel 80286 or upwardly compatible],
    [0x02], [Intel 80386 or upwardly compatible],
    [0x03], [Intel 80486 or upwardly compatible],
    [0x04], [Intel Pentium or upwardly compatible],
  ),
  caption: [CPU types defined for LE format. Values are stored in the `e32_cpu` field.]
) <tbl-cpu-types>

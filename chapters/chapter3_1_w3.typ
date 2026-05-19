#import "../template.typ"

= The W3 Container Format

This region wasn't declared in the title of this research work but 
W3 and W4 formats silently exists in the Microsoft Windows 3.x and 9x.

Much of information in this region was taken from the "Undocumented Windows Formats" book by Pete Davis and Mike Wallace.

== W3 File Layout 

On the @w3-layout presented file layout and as you can see, this file is very large.
Usually in the Windows 3.x this container uses for `VMM.386`.

#figure(
  ```
  ┌─────────────────────────┐
  │ MZ Header               │────+
  ├─────────────────────────┤    │ Ignore the e_lfarlc = 0x40  
  │ MZ relocations          │    │ rule. Usually it doesn't affect
  │ DOS executable image    │    │
  ├─────────────────────────┤<───+ e_lfanew pointer very large
  │ W3 Container Header     │
  │ W3 Program Records     ───────────+++
  ├─────────────────────────┤         │││ Relative offsets
  │ LE File layout          <───────────+ to LE programs
  ├─────────────────────────┤         ││
  │ LE File layout          <──────────+  
  ├─────────────────────────┤         │
  ├─────────────────────────┤         │
  │ LE File layout          <─────────+
  └─────────────────────────┘
  ```,
  caption: "W3 file layout"
) <w3-layout>

Unfortunately, drivers within a `W3` file are somewhat mangled, although the mangling
is fairly minor and easy to rectify. 
First of all, the `e32_datapage` value of `LE` header is
changed to be relative to the beginning of the `MZ` header for the `W3` file. 
Normally this is relative to the beginning of the `MZ` header of the `LE` file. 
Of course, in a `W3` file, the stubs for virtual drivers 
have been stripped to save space. 

The changing of the `e32_datapage` value is weird though, 
because none of the other offset fields are changed at all.
The other mangling has to do with the Non-Resident name table. 

The Non-Resident
name table is usually the last section of an LE file. In the case of W3 files, however,
all Non-Resident name tables have been removed, so if you extract the LE files, you'll
need to build one for it. This is a fairly simple process, however.

== W3 Header

W3 header presented on the @w3-layout looks pretty simple. 
On the @tbl-w3-header presented full header of the W3 container 

#figure(
  table(
    columns: (auto, auto, auto),
    align: (center, left, left),
    inset: 6pt,
    stroke: 0.5pt,
    table.header(
      [*Type*], [*Name*], [*Value*]
    ),
    [`BYTE[2]`], [`w3_magic`], [ASCII "W3" signature],
    [`WORD`], [`w3_winver`], [Windows version],
    [`WORD`], [`w3_modcnt`], [Number of programs in the container],
    [`BYTE[10]`], [`w3_res`], [Padding],
    [`W3REC[N]`], [`w3_moddir`], [W3 records array]
  ),
  caption: [W3 Header layout]
) <tbl-w3-header>

After the W3 header follows the array of `W3REC` records. The length of this array defines by the
`w3_modcnt` field.

#figure(
  table(
    columns: (auto, auto, auto),
    align: (center, left, left),
    inset: 6pt,
    stroke: 0.5pt,
    table.header(
      [*Type*], [*Name*], [*Value*]
    ),
    [`BYTE[8]`], [`w3_modname`], [Fixed 8-byte string (no zero terminated)],
    [`DWORD`], [`w3_modhdr`], [Offset to the module LE header],
    [`DWORD`], [`w3_cbmodhdr`], [Count bytes in the module header],
  ),
  caption: [W3 Record]
) <tbl-w3-record>


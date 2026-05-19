#import "../template.typ" as util

== Fixup Page Table


The fixup records table are array of fixup records and
offset into fixup records are relative to the current page. 
Fixup page table serves to identify fixup records into code and data segments offset.

Fixup page table starts by the `e32_fpagetab` offset from a start of `LE` header and presents an array of 32-bit unsigned integers.
Count of fixup pages is a
`pages# + 1`. 

#figure(
```
┌─────┬─────┬─────┬─────┐
│     Page Offset #1    │
├─────┼─────┼─────┼─────┤
│     Page Offset #2    │
├─────┼─────┼─────┼─────┤
│     Page Offset #...  │
├─────┼─────┼─────┼─────┤
│     Page Offset #n    │
├─────┼─────┼─────┼─────┤
│     End of Table      │
└─────┴─────┴─────┴─────┘

```,
  caption: [Fixup Page table]
)


Each `DWORD` contains offset into Fixup Record Table
of first fixup in the current page. 
Last `DWORD` contains size of
fixup record table in bytes. 
I.e. substraction contains `(DWORD + 1)` with current `DWORD` is fixup table size for current page.

== Fixup Record Table

Fixup Record table is the most complex structure in the `LE` executable.
Starts by the `e32_frectab` offset from the start of a Program Header.

The first byte of each fixup record defines the address type `Atp` and source type `Rtp`

#figure(
```
┌─────┬─────┬─────┬─────┬─ ─ ─┬─ ─ ─┬┬ ─ ─ ┬┐
│ Atp │ Rtp │  Off/Cnt  │  Data...  ││Relcs││    
└─────┴─────┴─────┴─────┴─ ─ ─┴─ ─ ─┴┴ ─ ─ ┴┘
└─────────────────┬─────────────────┘
      Fixup record mandatory part
Address Type:    8-bit
Relocation Type: 8-bit
Offset or count (16-bit) of offsets list 
Some data (typeof depends on Rtp)
```,
  caption: [Fixup Record template]
)

The following next table presents an #util.code("Address Type", "Atp") possible
definitions.

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, left, left),
    inset: 6pt,
    stroke: 0.5pt,
    [*Atp value*], [*Description*], [*Size*],
    [0x00], [8-bit fixup], [1 byte],
    [0x02], [16-bit selector (segment)], [2 bytes],
    [0x03], [16:16 far pointer (selector + offset)], [4 bytes],
    [0x05], [16-bit offset], [2 bytes],
    [0x06], [16:32 far pointer (selector + offset)], [6 bytes],
    [0x07], [32-bit offset], [4 bytes],
    [0x08], [32-bit self-relative offset], [4 bytes],
  ),
  caption: [`Atp` definitions. Values are stored in the low 4 bits of the first byte of a fixup record.]
) <tbl-frec-atp>

Also, the `Atp` field contains information continuation of current record:
#figure(
  table(
    columns: (auto, auto, auto),
    align: (center, left, left),
    inset: 6pt,
    stroke: 0.5pt,
    [*Mask (Atp & ...)*], [*Meaning when set*], [*Meaning when clear*],
    [0x10], 
    [
      #set par(leading: 0.6em)
      Fixup to 16:16 alias (target object requires alias)
    ], 
    [
      #set par(leading: 0.6em)
      Normal fixup
    ],
    [0x20], 
    [
      #set par(leading: 0.6em)
      The `Off/Cnt` field contains a count of following offsets
    ], 
    [
      #set par(leading: 0.6em)
      The `Off/Cnt` field is a single offset
    ],
  ),
  caption: [Additional `Atp` flags (bits 4 -- 5 of the first byte).]
) <tbl-frec-atp-continue>

After the source type follows the #util.code("relocation type byte", "Rtp"). Full available definitions
presented in the next table.

#figure(
  table(
    columns: (auto, auto),
    inset: 6pt,
    stroke: 0.5pt,
    [*Rtp & 0x03*], [*Description*],
    [0x00], [Internal reference],
    [0x01], [Import by ordinal],
    [0x02], [Import by name],
    [0x03], [Fixup via Entry Table],
  ),
  caption: [`Rtp` definitions. Stored in bits 0 -- 1 of the `nr_flags` field.]
) <tbl-frec-rtp>

The relocation type field contains a special additive flag,
which completely defines the layout of the fixup record.

#figure(  
  table(
    columns: (auto, auto, auto),
    align: (center, left, left),
    inset: 6pt,
    stroke: 0.5pt,
    table.header(
      [`(Rtp & ...) != 0`], [*True*], [*False*]
    ),
    [0x04], [
      #set par(leading: 0.6em)
      An additive value trails the fixup record before the offset list
    ], [
      #set par(leading: 0.6em)
      The additive value is missing. (Doesn't exists in the record) 
    ],
    [0x10], [32-bit Target offset], [16-bit target offset],
    [0x20], [32-bit Additive fixup flag], [16-bit Additive fixup flag],    
    [0x40], [16-bit `object#` or a `module#`], [8-bit `object#` or a `module#`],
    [0x80], [8-bit procedure ordinal], [16-bit procedure ordinal]
  ),
  caption: [Relocation Type data sizes]
) <tbl-frec-rtp-add>

=== Internal Fixup record

If the `Rtp` field conjuncted by type mask returns zero (see @tbl-frec-rtp)
the layout of Internal fixup record still depends on resolved `Atp`
and `Rtp` masks.

#figure(
```
┌─────┬─────┬─────┬─────┬─ ─ ─┬─ ─ ─┬ ─ ─ ┬┐
│ Atp │ Rtp │  Off/Cnt  │  Object#   Relcs││    
└─────┴─────┴─────┴─────┴─ ─ ─┴─ ─ ─┴ ─ ─ ┴┘
            │           └─────┬─────┘
            │           │ 16-bit Object# := (Rtp & 0x40) != 0
            │           │ 
            └─────┬─────┘
        if (Atp & 0x20) != 0 -> Cnt
        else -> Off 
        
```,
  caption: [Internal Fixup]
)



=== Import by ordinal Fixup Record

The Import fixup record data differs with the record
if it would be internal reference.

#figure(
```
┌─────┬─────┬─────┬─────┐
│ Atp │ Rtp │  Off/Cnt  │    
├─ ─ ─┼─ ─ ─┼─ ─ ─┼─ ─ ─┼─ ─ ─┬─ ───┐
│  Module#  │        Ordinal        │
├─ ─ ─┼─ ─ ─┼─ ─ ─┼─ ─ ─┼─ ─ ─┴─ ─ ─┘
│   Additive Value      │ Relcs list
└─ ─ ─┴─ ─ ─┴─ ─ ─┴─ ─ ─┘
                        └─────┬─────┘
                        If (Atp & 0x20) != 0
```,
  caption: [Ordinal Import Fixup]
) <frec-imp-ord-listing>

Memory layout objects on the @frec-imp-ord-listing 
which was drawn not by the "solid line" are optional or
having variant size which is depending on the `Atp` and `Rtp` masks.  
 - `Module#` might be 8-bit or 16-bit;
 - `Ordinal` might be 8-bit or 16-bit or 32-bit;


If the Additive Flag is set in the `Rtp` bitmask, the "Additive Value" (see @frec-imp-ord-listing) is added to the address derived from the target entry point. This field is a `WORD` value when the "32-bit Additive Flag" bit in the target flags field is clear and a `DWORD` value when the bit is set.

=== Import by name Fixup Record

The fixup record of runtime import by name looks like the 
fixup of anonymous runtime import (see @frec-imp-ord-listing).

#figure(
```
┌─────┬─────┬─────┬─────┐
│ Atp │ Rtp │  Off/Cnt  │    
├─ ─ ─┼─ ─ ─┼─ ─ ─┼─ ─ ─┼─ ─ ─┬─ ───┐
│  Module#  │     Name Offset       │
├─ ─ ─┼─ ─ ─┼─ ─ ─┼─ ─ ─┼─ ─ ─┴─ ─ ─┘
│   Additive Value      │ Relcs list
└─ ─ ─┴─ ─ ─┴─ ─ ─┴─ ─ ─┘
                        └─────┬─────┘
                        If (Atp & 0x20) != 0
```,
  caption: [Import by Name Fixup]
) <frec-imp-name-listing>

The `Name Offset` field is an offset into the Import Procedure Name Table. It is a 16-bit value when the 32-bit `Rtp` Flag bit in the target flags field is clear and a 32-bit value when the bit is set. 

Other characteristics except the `Name Offset` define the same way 
like an Import by ordinal.

=== Entry Table Fixup Record

The Entry Table fixup (or a "Fixup via Entry Table") record in the table
makes the point for the loader that entry point by following ordinal must be
relocated during the run-time.

#figure(
```
┌─────┬─────┬─ ─ ─┬─ ─ ─┬─ ─ ─┬─ ─ ─┬─ ─ ─┬─ ─ ─┬ ─ ─ ┬┐
│ Atp │ Rtp │  Off/Cnt  │  Entry#   │ Additive  │Relcs││    
└─────┴─────┴─ ─ ─┴─ ─ ─┴─ ─ ─┴─ ─ ─┴─ ─ ─┴─ ─ ─┴ ─ ─ ┴┘
                        └─────┬─────┘
                         16-bit Entry# := (Rtp & 0x40) != 0
```,
  caption: [Fixup via Entry Table record]
)

The fixup via entry table record applies to the local Entry Table.
If Entry Table of the module is empty but fixup records still exists,
there's a problems due the parsing of Entry Table or Fixup record Table.

The `Entry#` or an ordinal of given entry point might be 8 or 16-bit.

== Import Module Table

The Import module table stores in the Linear Executable program/library by
the `e32_impmodtab` offset from the beginning of the `LE` header.
It contains symbols of run-time import programs or libraries, not functions/procedures.

The import module table is just an array of Pascal-Strings 
with fixed length which is defined in the `LE` header (see `e32_impmodcnt`) 

#figure(
  rect()[
    #set par(leading: 0.65em)
    #set align(left)
    The Import Module Table doesn't use the names of file system objects (i.e. programs or libraries from the point of view of the file system)!

    Symbols what presented here are records of Resident Name Table
    *by the zero ordinal* of each module which entry points will be used by
    the current module during the run-time.
  ]
)

Also knowing of the `e32_impmodcnt` value helps to avoid tables overlap problems.
If the DLL which contains just Forwarder Entries and no more code and data,
the padding between the tables could be missed. By this reason,
You may read Import module table and Resident Name table as a single table
with a corrupted strings because of Ordinal records in the Resident Names table. 

== Import Procedure Table

Same with the Import Module table the Import Procedure table looks like an array
of Pascal Strings. But the end of the table defines by the last Pascal-String.

==== Runtime Imports Symbols remark

The Import Procedure table contains case-sensitive Pascal-strings like 
resident names table (see @name-record). But Microsoft `LNK386.EXE` follows the same algorithm with the `LINK.EXE` for 16-bit segmented programs ignores the case of module API.
That's why after the resolving of symbols you will get the `INVALIDCASE` named list
of DLLs and executables.

In the modern IBM `LX`-linked modules which provide generic/template API or require them, you will see the Itanium ABI-mangled symbols. And they're case sensitive.
This fact is a proof of `LE` and `LX` symbols storage concept.

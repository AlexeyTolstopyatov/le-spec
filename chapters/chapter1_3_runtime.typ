#import "../template.typ" as util

== Entry Points Table

#util.term("Entry points table", "Entry Table") is very complex
structure in the flat executable file format. 
Same with the #util.code("segmented executables", "NE") from OS/2 1.x
and Windows 1.x, the entry table contains entry bundles.

#figure(
  rect()[
    #set par(leading: 0.65em)
    #set list(indent: 1cm)
    #set align(left)
    Despite the fact that many different sources indicate 
    the existence of only two types of entry bundles, the `exe_vxd.h` of 
    leaked Windows debugger and `exe386.h` from Microsoft OS/2 2.0 SDK
    determines next types of entry point:
      - Unused Entry;
      - 16-bit Entry;
      - 16-bit Callgate Entry;
      - 32-bit Entry;
      - Forwarder Entry;

    #align(center)[
      ```
      type := typ & 0x7F;
      has_add_typinfo := (typ & 0x80) != 0;
      ```
    ]
  ]
)

The #util.term("bundle of entry points", "Entry Bundle")
contains data like an `object#` and type for all entry points which
store in the current bundle. 
Next listing is a try to visualize a flat memory model of imagimary
entry table.

#figure(
```
┌─────┬─────┬─────┬─────┬─────┬┬─────┬─────┬─────┬─────┬────┐
│ Cnt │ Typ │  Object#  │ ... ││ ... │ Cnt │ Typ │ ... │ 00 │  
└─────┴─────┴─────┴─────┴─────┴┴─────┴─────┴─────┴─────┴────┘
                        └─────┬──────┘           └──┬──┘  
└───────────┬───────────┘   Entries  │            Entries
│   Entry Bundle header              │
└────────────────┬───────────────────┘
            Entry Bundle
```,
  caption: [Entry Table layout]
)

Entry Table starts with the `BYTE` which defines count of entry points
in the given bundle. If entries count equals zero, this is a mark of
the end of an Entry Table.

=== Entry Bundle for a Target object

Entry bundle header differs for other types of entries.
If entry points bundle contains Forwarder entries -- the target `object#` for entries in bundle ignores (doesn't exists at all).
Linker and operating system sets `Object#` to zero.

#figure(
```
┌─────┬─────┐
│ Cnt │ Typ │
└─────┴─────┘
└──┬──┘
 8-bit
```,
  caption: [Forwarder or Unused Entry Bundle header]
)

If `object#` exists and reads by the operating system loader,
there're exist two ways.
 - `object# = 0` then offset of each entry point in bundle are absolute file offset;
 - `object#` not zero then each entry point (depending on the target object flags) have a virtual address!

Use Object Table and Module Pages Table to resolve the position of the
entry point.
#figure(
```
┌─────┬─────┬─────┬─────┐
│ Cnt │ Typ │  Object#  │
└─────┴─────┴─────┴─────┘
            └─────┬─────┘
                16-bit
```,
  caption: [Entry Bundle header]
)

All what is going next after header will be present
an array of entry points with the type declared in the entry bundle
header. Length of this array defines by the #util.code("count field in the header", "Cnt").

#figure(
  rect()[
    #set par(leading: 0.65em)
    #set align(left)
    Entry Table represents a module exports which will be resolved
    during the another application run-time. 
    Procedure ordinals enumeration starts from 1.
    Entry Point at the `0`-ordinal doesn't exist, but 
    ordinal `0` exists and reserved by module.
  ]
)

=== Unused Entry

Unused Entry can't have a body instead of other types of enties.
This is a way how to place export procedures `@1` and `@100`, for example.
Linker skips the count of unused entries and starts new bundle.

=== 16-bit Entry

After Entry Bundle, defined in previous region, follows an array of 16-bit entry points.
For 16-bit program code entry point defines like on the next listing.

#figure(
```
┌─────┬─────┬─────┐
│ Flg │   Offset  │
└─────┴─────┴─────┘
      └─────┬─────┘
      Look at the target object flags too.
      Usually (if object doesn't have invalid pages)
      this is an offset from the object start.
```,
  caption: [16-bit Entry]
)

Flags `BYTE` field has a special bitmask.
 
#figure(
  table(
    columns: (auto, auto),
    align: (center, left),
    inset: 6pt,
    stroke: 0.5pt,
    table.header(
      [*Byte*], [*Description*]
    ),
    [0x01], [Exported Entry],
    [0x02], [Uses Shared `.DATA`],
    [0xF8], [Parameter work mask],
  ),
  caption: [Object flags (low byte)]
) <tbl-ent16-flags>

=== 16-bit Call Gate Entry

The Intel 286 Call Gate Entry Point type is needed by the loader only if ring-2 segments 
are to be supported 
(Object flag bitmask includes `IO PRIVILEGIES` flag).
The I286 Call Gate entries contain 2 extra bytes which are used by 
the loader to store an LDT callgate selector value

#figure(
```
┌─────┬─────┬─────┬─────┬─────┐
│ Flg │   Offset  │ Call Gate │
└─────┴─────┴─────┴─────┴─────┘
                  └─────┬─────┘
                  Set to zero in the file. 
                  Stores LDT selector during a run-time.
```,
  caption: [16-bit Call Gate Entry]
)

The `DOSCALL1.DLL` from the MS OS/2 stores I286 Call Gate entries.
Examples of them will be the famous `DosCopy` procedure or `DosRead`/`DosWrite` procedures.  

Flags of the Call Gate entry are the same with the 16-bit entry flags.
So, see the @tbl-ent16-flags.

=== 32-bit Entry

Same with the 16-bit entries -- 32-bit entries relate to objects with
`USE_32` flag in their bitmasks.

#figure(
```
┌─────┬─────┬─────┬─────┬─────┐
│ Flg │        Offset         │
└─────┴─────┴─────┴─────┴─────┘
      └───────────┬───────────┘
                32-bit
```,
  caption: [32-bit Call Gate Entry]
)

The `Flg` field contains same flags presented in the @tbl-ent16-flags

=== Forwarder Entry

#figure(
  rect()[
    #set par(leading: 0.65em)
    #set align(left)
    A #util.code("Forwarder entry", "forwarder") is an entry point whose value is an imported reference. 
  ]
)

When a load time fixup occurs whose target is a `forwarder`, 
the loader obtains the address imported by the `forwarder` 
and uses that imported address to resolve the fixup.

A `forwarder` may refer to an entry point in 
another module which is itself a `forwarder`, so there can be a chain of forwarders. 
The loader will traverse the chain until it finds a non forwarded entry point 
which terminates the chain, and use this to resolve the original fixup. 
Circular chains are detected by the loader and result in a load time error. 

#figure(
```
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│ Flg │  Module#  │ Ordinal / Name offset │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┘
      │           └───────────┬───────────┘
      │           │ Depending on the flags bitmask. 
      │           │ Stores to procedure ordinal 
      │           │ or an offset to the name in
      │           │ [Import Procedure Names] table.
      └─────┬─────┘
      Index of the module name
      in the [Import Modules Names] table
```,
  caption: [16-bit Call Gate Entry]
)

For the forwarder entries the flags definitions are different.

#figure(
  table(
    columns: (auto, auto),
    align: (center, left),
    inset: 6pt,
    stroke: 0.5pt,
    table.header(
      [*Byte*], [*Description*]
    ),
    [0x01], [Import by ordinal],
    [0xF7], [Reserved!],
  ),
  caption: [Object flags (low byte)]
) <tbl-entfwd-flags>

A maximum of 1024 `forwarders` is allowed in a chain; more than this results in a run-time time error. 

Forwarders are useful for merging and recombining API calls into different sets of libraries, 
while maintaining compatibility with applications. 
_For example, if one wanted to combine `MONCALLS`, `MOUCALLS`, and `VIOCALLS` into a single libraries, 
one could provide entry points for the three libraries that are forwarders pointing to the common 
implementation._

== Resident Names Table

Resident names table contains export procedures which
must be kept in the system memory during the module run-time.
It is intended to contain the exported entry point names that are frequently dynamically linked to by name.

Resident name record consists of procedure ordinal word and pascal string of the procedure name.

#figure(
```
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│ Len │  Name ASCII bytes ... │  Ordinal  │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┘
└──────────────┬──────────────┘
         Pascal String
```,
  caption: [Procedure Name record]
) <name-record>

The end of the table defines by the zero length of the next Pascal String.

== Non-Resident Names Table

Non-resident names are not kept in memory and are read from the file 
when a dynamic link reference is made. 
Exported entry point names that are infrequently dynamically linked 
to by name or are commonly referenced by ordinal number should be 
placed in the non-resident name table.

#figure(
  rect()[
    #set par(leading: 0.65em)
    #set align(left)
    Non-Resident names Table pointer in the Linear Executable header
    declares the offset from the start of file!
    This is a once structure in the LE layout which location defines
    not from start of program header.  
  ]
)

Same with the Resident Names table -- it just an array of records (see @name-record) with undefined count of entries.

The end of the table defines by the zero length of the next Pascal String.
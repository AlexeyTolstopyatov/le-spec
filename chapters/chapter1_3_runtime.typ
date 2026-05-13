#import "../template.typ" as util

== Entry Points Table

#util.term("Entry points table", "Entry Table") is very complex
structure in the flat executable file format. 
Same with the #util.code("segmented executables", "NE") from OS/2 1.x
and Windows 1.x, the entry table contains entry bundles.

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


=== Entry Bundle types

Despite the fact that many different sources indicate the existence of only two types of entry bundles, the `exe_vxd.h` of 
leaked Windows debugger and `exe386.h` from Microsoft OS/2 2.0 SDK
determines next types of entry point:
 - Unused Entry;
 - 16-bit Entry;
 - Callgate (80x86 specific) 16-bit Entry;
 - 32-bit Entry;
 - Forwarder Entry;
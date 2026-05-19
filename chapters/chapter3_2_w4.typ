#import "../template.typ" as util

= The W4 Container Format

The `W4` file format is very similar to the `W3` file format, except once. 
The `W4` container uses a special compression algorithm. 
In fact, the compression used in the `W4` file is exactly the same as the Double Space compression used in double-space drives. 

The `W4` compression algorithm is called a #util.term("Lempel/Ziv/Welch", "LZW") compression algorithm", named after the three people who contributed to its design. 
The `W4` file, when decompressed, actually contains a `W3` file inside, so once you've decompressed the `W4` file, you can traverse the W3 file structure described earlier (see @w3-layout).

In the Appendix A presented the decompression algorithm.

== W4 Header

#figure(
  table(
    columns: (auto, auto, auto),
    align: (center, left, left),
    inset: 6pt,
    stroke: 0.5pt,
    table.header(
      [*Type*], [*Name*], [*Value*]
    ),
    [`BYTE[2]`], [`w4_magic`], [ASCII "W4" signature],
    [`WORD`], [`w4_res1`], [Reserved],
    [`WORD`], [`w4_cbchunk`], [Chunk size],
    [`WORD`], [`w4_chunkcnt`], [Count of chunks],
    [`BYTE[2]`], [`w4_dsmag`], [ASCII "DS" magic],
    [`BYTE[6]`], [`w4_res3`], [Usually `NULL`s]
  ),
  caption: [W4 Header layout]
) <tbl-w4-header>

== W4 Decompression

So, instead of explain
ing what a Shannon-Fano table is, I will only go into how it specifically affects W4
files. At its most basic, the Shannon-Fano table provides codes that give the depth and
count of repeated data in the compressed data.
The Shannon-Fano table for the W4 compression algorithm is shown in @tbl-shf-definitions,
@tbl-depth and @tbl-count

#figure(
  table(
    columns: (auto, auto),
    align: (right, left),
    inset: 6pt,
    stroke: 0.5pt,
    table.header(
      [*MSB`...`LSB*], [*Description*]
    ),
    [`xxxx01`], [`1xxxx` uncompressed byte],
    [`xxxx10`], [`0xxxx` Uncompressed byte],
  ),
  caption: [Shannon-Fano Table]
) <tbl-shf-definitions>

#figure(
  table(
    columns: (auto, auto),
    align: (right, left),
    inset: 6pt,
    stroke: 0.5pt,
    table.header(
      [*MSB`...`LSB*], [*Description*]
    ),
    [`00000000`], [Exit Code],
    [`xxxxxx00`],[`xxxxxx = 1 - 63`],
    [`11111100`], [`63`],
    [`xxxxxxxx011`], [`64 +  xxxxxxxx = 64 - 319`],
    [`xxxxxxxxxxxx111`], [`320 + xxxxxxxxxxxx = 320 - 4414`],
    [`111111111111111`], [`(4415)` = Check Buffer],
  ),
  caption: [Depth definitions]
) <tbl-depth>

#figure(
  table(
    columns: (auto, auto),
    align: (right, left),
    inset: 6pt,
    stroke: 0.5pt,
    table.header(
      [*MSB`...`LSB*], [*Description*]
    ),
    [`1`], [`2`],
    [`010`], [`3`],
    [`110`], [`4`],
    [`xx100`], [`5 + xx = 5 - 8`],
    [`xxx1000`], [`9 + xxx = 9 - 16`],
    [`xxxx10000`], [`17 + xxxx = 17 - 32`],
    [`xxxxx100000`], [`33 + xxxxx = 33 - 64`],
    [`xxxxxx1000000`], [`65 + xxxxxx = 65 - 128`],
    [`xxxxxxx10000000`], [`129 + xxxxxxx = 129 - 256`],
    [`xxxxxxxx100000000`], [`257 + xxxxxxxx = 257 - 512`],
    [`000000000`], [Done]
  ),
  caption: [Count definitions]
) <tbl-count>

The idea of how the Shannon-Fano table works is quite simple. At this point, it's
probably best just to examine the code in Appendix A; 
in particular, `w4_extract()`
and `load_buffer()`. 
Notice that `w4_extract()` pulls only as many bits from
dwMiniBuffer as it needs. After pulling a depth value, it calls `load_buffer()` to
shift in some new bits. Then it looks for the count value, again pulling only as many
bits as it needs, and then calling `load_buffer()` to fill up `buffer` again.

==== Application

The exapmle of W3 files are `VMM.386` from Windows 3.x and `WIN386.EXE` from Windows 9x.
Also the example of file with W4 container is `VMM32.vxd`.
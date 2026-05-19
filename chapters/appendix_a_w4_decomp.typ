= Appendix A

#set align(center)
```c
#include <stdio.h>
#include <stdlib.h>
#include <memory>
#include <string.h>

void load_buffer(DWORD* buff, BYTE** src, WORD* used, count) {
  buff >>= 1;
  while ((*used)--) {
    buff += (DWORD) **src << 24L;
    *src += 1;
    *count = 8;
  }
}
/// Decompress the W4 Container
/// \param src given source bytes
/// \param dst destination file bytes
/// \param size safe length of given source
void w4_extract(BYTE* src, BYTE* dst, WORD size) {
  DWORD buffer = 0;
  WORD count;        // Count and Depth of compressed "string"
  WORD used;         // Count of bits used by the last "code"
  WORD depth;
  WORD dsti;         // Destanation index
  WORD temps = size; // Temporary size
  WORD i;            // Global iterator

  BYTE* tempb = src;
  // Load up the mini buffer (buffer) with the first 4 bytes.
  // Expecting something like that
  // msb             buffer            lsb
  // +--------+--------+--------+--------+
  // | BYTE 3 | BYTE 2 | BYTE 1 | BYTE 0 |
  // +--------+--------+--------+--------+
  dsti = 0;
  for (i = 0; i <= 3; i++)
    buffer = (buffer >> 8) + ((DWORD)*src++ << 24);
  
  count = 8;
  depth = 1;
  while (depth) {
    // Too many conditions will be written later
  }
}
```
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
WORD w4_extract(BYTE* src, BYTE* dst, WORD size) {
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
  // Iterate in the source buffer while 
  // depth more than zero
  while (depth) {
    if ((buffer & 0x0003L) == 0x0001L
        || (buffer & 0x0003L) == 0x0002L) {
      if (--size == 0xFFFF) {
        // Error: Overrun of data, force exit required
        return 0;
      }
      // If no overrun ->
      dst[dsti++] = (BYTE)(((buffer & 0x01FCL) >> 2L) | 
                          ((buffer & 0x0001L) << 7L));
    } else {
      // Depth data is compressed
      if ((buffer & 0x0003L) == 0x0001L) {
        // (0-63)
        depth = (WORD)((buffer & 0x00FCL) >> 2);
        used  = 8;
      } else if ((buffer & 0x0007) == 0x0003L) {
        // (64-319)
        depth = (WORD)((buffer & 0x07F8L) >> 3) + 0x0040;
        used  = 11;
      } else if ((buffer & 0x0007L) == 0x0007L) {
        // (320-4414)
        depth = (WORD)((buffer & 0x07FF8L) >> 3) + 0x0140;
        used  = 15;
      } else {
        // Error: Invaild depth data, force exit
        return 0;
      }
      // After the computing depth: if depth greather than zero
      // and not a check buffer, load nuffer as needed.
      //  (depth > 0) * (depth not in 4415-320)
      if ((depth) && (depth != 0x113F)) { 
        load_buffer(&buffer, &src, &used, &count);
        // Get count
        if ((buffer & 0x00001L) == 0x00001L) {
          // 2
          count = 2;
          used  = 1;
        } else if ((buffer & 0x00003L) == 0x0002L) {
          // 3-4
          count = (WORD)((buffer & 0x0004L) >> 2L);
          used  = 3;
        } else if ((buffer & 0x00007L) == 0x00004L) {
          // 5-8
          count = (WORD)((buffer & 0x00018L) >> 3L) + 5;
          used  = 5;
        } else if ((buffer & 0x0000FL) == 0x0008L) {
          // 9-16
          count = (WORD)((buffer & 0x000701L) >> 4L) + 9;
          used  = 7;
        } else if ((buffer & 0x0001FL) == 0x0010L) {
          // 17-32
          count = (WORD)((buffer & 0x001E0L) >> 5L) + 17;
          used  = 9;
        } else if ((buffer & 0x0003FL) == 0x00020L) {
          // 33-64
          count = (WORD)((buffer & 0x007C0L) >> 6L) + 33;
          used  = 11;
        } else if ((buffer & 0x0007FL) == 0x00040L) {
          // 65-128
          count = (WORD)((buffer & 0x01F80L) >> 7L) + 65;
          used  = 13;
        } else if ((buffer & 0x000FFL) == 0x00080L) {
          // 129-256
          count = (WORD)((buffer & 0x07F00L) >> 8L) + 129;
          used  = 15;
        } else if ((buffer & 0x00100L) == 0x00100L) {
          // 257-512
          count = (WORD)((buffer & 0x01FE00L) >> 9L) + 257;
          used  = 17;
        } else {
          // Bad data but handle as if it were an exit condition
          // Error: bad data. Exit at the current stage
          depth = 0;
          count = 0;
          used  = 9;
        }
        // Copy count bytes of data from depth bytes back
        while (count--) {
          if (--size == 0xFFFF) {
            // Error: Overrun data
            return 0;
          }
          dst[dsti] = dst[dsti - depth];
          dsti++;
        }
      } else {
        // if ((depth) && (depth != 0x113F)) { ... }
        // else -> 
        // In other words: if the size of remaining data is zero
        // needs to exit. We finally done it
        if ((depth == 0x113F) && (size == 0x0000)) {
          depth = 0;
        }
      }
      load_buffer(&buffer, &src, &used, &count);
    } 
  }
  return desti;
}
/// Extracts the bytes of W3 container by given W4 file
/// \param w4file source file which needs to decompress
/// \param name file name string
DWORD extract_w3(FILE* w4file, char* name) {
  FILE w3file;
  MZHEADER mz;
  W4HEADER w4;
  DWORD* chunks;
  DWORD start, end;
  BYTE* src;
  BYTE* dst;
  WORD chunki;
  WORD destsize;
  DWORD i;
  if ((w3file = fopen("TMPW3OBJ", "wb")) == NULL) {
    printf("Unable to open file for output\n");
    return 1;
  }
  fread(&mz, sizeof(MZHEADER), 1, w4file);
  // Check: if given header is bad: 
  // 1) no MZ signature;
  // 2) zero e_lfanew offset;
  if (!has_dosexe(&mz)) {
    printf("Doesn't have DOS magic signature!\n");
    return 1;
  }
  // Also check the W4 header start. If given bytes 
  // not present the W4 header -> we must to go quit.
  // And close the output data stream of cause
  fseek(w4, mz.e_flanew, 0); // make an offset from the beginning of file
  fread(&w4, sizeof(W4HEADER), 1, w4file);
  if (!has_w4(&w4)) {
    printf("Doesn't have W4 container signature!\n");
    fclose(w3file);
    return 1;
  }
  // Allocate the space for chunk table. If allocation bad -> 
  // close data stream and exit.
  chunks = malloc(w4.chunkcnt * 4);
  if (chunks == NULL) {
    printf("Required chunk table size is %d. Allocated 0\n", w4.chunkcnt);
    return 1;
  }
  // Check the source and destination data streams. 
  // If any will be corrupted -> close data stream & force exit.
  src = malloc(w4.cbchunk);
  if (src == NULL) {
    printf("Not enough memory for source bytes");
  }
  dst = malloc(w4.cbchunk * 2);
  if (dst == NULL) {
    printf("Not enough memory for dest bytes");
  }
  // If we're stay here: data streams and W4 container was read.
  // nothing happened. Then its time to read compressed chunks.
  fread(chunks, w4.chunkcnt, 4, w4file);
  // Pad W3 container so thet offsets in the list of programs
  // will match up
  end = mz.e_lfanew - sizeof(mz);
  fwrite(&mz, sizeof(mz), 1, w3file);
  for (i = 0; i < end; ++i) {
    fputc(0, w3file);
  }
  // Copy decompressed chunks of W3 image.
  for (chunki = 0; i < w4.chunkcnt; ++chunki) {
    start = chunks[chunki];
    if (chunki == w4.chunkcnt) {
      end = fseek(w4file, 0x0L, SEEK_END);
    } else {
      end = chunks[chunki + 1];
    }
    // Read the current chunk right now and decompress given data
    fseek(w4file, start, SEEK_SET);
    fread(src, (WORD)(end - start), 1, w4file);
    memset(dst, 0xE5, w4.cbchunk);
    if ((WORD)(end - start) != w4.cbchunk) {
      destsize = extract_w4(src, dst, w4.cbchunk);
      if (!destsize) {
        fclose(w3file);
        return 1;
      }
      fwrite(dst, (WORD)destsize, 1, w3file);
    } else {
      fwrite(src, (WORD)(end - start), 1, w3file);
    }
  } 
  // Finally data has been decompressed and moved
  free(w3file);
  free(chunks);
  free(src);
  free(dst);
}
```
#import "../template.typ" as utils

= Introduction

This document is intended to describe the interface that is used by language 
translators and generators as their intermediate output to the linker for the Microsoft OS/2 2.0 operating system.
The linker will generate the executable module that is used by the loader to invoke the `*.EXE` and `*.DLL` programs at execution time.

This material was compiled from Microsoft OS/2 2.0 SDK sources, leaked #utils.term("Windows Debugger", `windbg`), Open Watcom documents and was wrote Alexey Tolstopyatov the Tomsk State University student

== Linear Executable File Format

#utils.code("Linear Executable", "LE") is file format for executable code designed for 16/32-bit protected mode operating systems. Originally used by the Microsoft OS/2 2.0 operating system, served as the file format for Virtual Device Drivers (`VxD`) in early versions of Windows, and adopted by various DOS extenders. 
Microsoft Windows 3.x and 9x used special archive format for `VxD` drivers -- `W3` and `W4` executable containers.

#figure(
  rect()[
    #set par(leading: 0.65em)
    #set align(left)
    Do not use IBM's expertise to determine the LE format correctly. The standard IBM OS/2 executable module format is a logical development of this model, which is not backward compatible!
  ]
)

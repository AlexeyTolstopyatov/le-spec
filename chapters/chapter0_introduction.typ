#import "../template.typ" as utils

= Introduction

This document is intended to describe the interface that is used by language 
translators and generators as their intermediate output to the linker for the Microsoft OS/2 2.0 operating system.
The linker will generate the executable module that is used by the loader to invoke the `*.EXE` and `*.DLL` programs at execution time.

This material was compiled from Microsoft OS/2 2.0 SDK sources, leaked #utils.term("Windows Debugger", `windbg`), Open Watcom documents and was written by Alexey Tolstopyatov the Tomsk State University student

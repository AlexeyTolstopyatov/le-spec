#import "../template.typ" as util

= Windows Virtual Device Driver Model

"VxD" is the device driver model used in the 386 enhanced mode of Windows 3.x, 
Windows 9x, and to some extent also by the Novell DOS 7, OpenDOS 7.01, and DR-DOS 7.02 (and higher) multitasker (TASKMGR). 

VxDs have access to the memory of the kernel and all running processes, as well as raw access to the hardware. Starting with Windows 98, Windows Driver Model was the recommended driver model to write drivers for, with the VxD driver model still being supported for backward compatibility, until Windows Me.

Also the virtual device drivers which built using this model contains a few parts
of code:
 - 16-bit Intel Real mode initialization code object;
 - 32-bit Intel Protected mode initialization code object;
 - 32-bit locked/unlocked code/data objects;
 - #util.code("Device Declaration Block", "DDB")

And no iterated or invalid data pages at all.

The 16-bit real mode code object contains program text which has been written
in the `VxD_REAL_MODE_INIT_SEG` macro, provided by the `VMM.inc`.
This code which round of macro opening and closing parts 
will become an `ICOD` object with the `16:16 Alias` and `USE_16` attributes.

The 32-bit initialization code and data segments defined by the `VxD_ICODE_SEG` and `VxD_IDATA_SEG` macros are present until `VMM` has completed initialization, 
at which time they are discarded, freeing the memory used by these sometimes cumbersome pieces of code. 
These initialization procedures can determine whether it is
safe to load the VxD or to bail out prior to further initialization. Thus, the VxD load can fail, the user can be notified, and there will be no memory wasted for the VxD when the VMM completes initialization.

The Locked code and data objects will become a `LCOD` and data objects with the `USE_32` attribute.

== Virtual Device Driver Header

At the end of Linear Executable header in the #util.code("padding field", "e32_res3") embeds the 
device driver header. 

#figure(
  table(
    columns: (auto, auto),
    align: (center, left),
    inset: 6pt,
    stroke: 0.5pt,
    table.header(
      [*Type*], [*Value*]
    ),
    [`DWORD`], [e32_winresoff],
    [`DWORD`], [e32_winreslen],
    [`WORD`], [e32_devid],
    [`WORD`], [e32_ddkver]
  ),
  caption: [VxD Header]
) <tbl-vxd-header>

The `e32_winresoff` (optional) contains an offset from the beginning of file
to the special information block and compiled Windows resource `*.res`.
Don't use Resource Table definitions of `LE` module.

The `e32_winreslen` field tells the length of compiled Windows resource file and special VxD Resource structure.

The `e32_devid` presents a Device ID for VxD and `e32_ddkver` presents a version
of Windows Device Driver Kit. Also you can read this `WORD` as an array of two `BYTE`s.

== Virtual Device Resource Block

The resource block of VxD presents the next structure which defines
two important values: the compiled resource file embedded into the `LE` module image
and the ordinal of Device Declaration Block entry point.

#figure(
  table(
    columns: (auto, auto),
    align: (center, left),
    inset: 6pt,
    stroke: 0.5pt,
    table.header(
      [*Type*], [*Value*]
    ),
    [`BYTE`], [type],
    [`WORD`], [id],
    [`BYTE`], [name],
    [`WORD`], [ordinal],
    [`WORD`], [flags],
    [`DWORD`], [size],
  ),
  caption: [VxD Resource block]
)

_According to personal assumptions, using the Ordinal field, you can find the number of the DDB entry point. I have no good reason to believe that this is correct, but I don't see any alternatives to determine the ordinal of the entry point_.

== Device Declaration Block

The device declaration block describes the virtual device to the `VMM`. 
It provides a VxD mnemonic, usually a somewhat descriptive title using `V` 
as the prefix and `D` as the suffix, such as `VJOYD`, suggesting a virtual
joystick driver for example. 

It also provides a major and minor version, the main control procedure, the device ID number, the initialization order, and control procedures for the V86 or Protected-Mode API.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (center, left, left, left),
    inset: 6pt,
    stroke: 0.5pt,
    table.header(
      [*Type*], [*Value*], [*Default*], [*Description*]
    ),
    [`DWORD`], [ddb_next], [0], [VMM reserved],
    [`WORD`], [ddb_version], [], [DDK version],
    [`WORD`], [ddb_dev_id], [`UNDEFINED_DEVICE_ID`], [Required Device ID],
    [`BYTE`], [ddb_dev_major], [0], [Major device number],
    [`BYTE`], [ddb_dev_minor], [0], [Minor device number],
    [`WORD`], [ddb_flags], [0], [],
    [`BYTE[8]`], [ddb_name], ["`        `" (8 spaces)], [VMM device mnemonic],
    [`DWORD`], [ddb_init_order], [`UNDEFINED_INIT_ORDER`], [The load order],
    [`DWORD`], [ddb_ctrl_offset], [], [`_Control_Proc` offset],
    [`DWORD`], [ddb_v86api_offset], [0], [Offset to API procedure],
    [`DWORD`], [ddb_pmapi_offset], [0], [`_Device_Init` offset],
    [`DWORD`], [ddb_v86api_csip], [0], [CS:IP of API entry point],
    [`DWORD`], [ddb_pmapi_csip], [0], [CS:IP of API entry point],
    [`DWORD`], [ddb_rmdata_ref], [0], [Real mode data reference],
    [`DWORD`], [ddb_srvtab_ptr], [0], [Pointer to service table],
    [`DWORD`], [ddb_srvtab_size], [0], [Number of services],
    [`DWORD`], [ddb_win32tab_ptr], [0], [Win32 services table],
    [`DWORD`], [ddb_prev4], [4.0], [Pointer to prev 4.0 DDB],
    [`DWORD`], [ddb_res0], [0], [Reserved],
    [`DWORD`], [ddb_res1], [], [Reserved],
    [`DWORD`], [ddb_res2], [], [Reserved],
    [`DWORD`], [ddb_res3], [], [Reserved]
  ),
  caption: [VxD Device Declaration block]
)

The field `ddb_flags` at the moment of writing is still unknown.
Far pointers like `ddb_v86api_csip` and `ddb_pmapi_csip` are set to `NULL` and
later fills by the operating system during the run-time.

== Are VxD Drivers are 32-bit or 16-bit?

Answer for this question hides in the `VMM.inc` and whole Windows DDK insights.
If you try to disassemble a few virtual drivers you will see that far 
pointer to the entry point always points to the 16-bit `.CODE` object.

This entry point uses by `VMM` to wake up device driver. 
Depending on Windows DDK macros might be different. 

#figure(
```yasm
; Object# : 3.
; Pages#  : 1 (present in the file)
; Virtual Size : 0x00000084
; Flags (0x00001005): [Readable] [Executable] [16:16 Alias Required] [USE_16]
; Segment type: Pure code
; segment para public .CODE
assume cs:03
assume es:03, ss:00, ds:03, fs:00, gs:00

03:0000                 public start
03:0000 start           proc near
03:0000                 cmp     bx, 1
03:0003                 jz      loc_C0007016
03:0007                 mov     ax, 0
03:000A                 call    sub_C0007024
03:000D                 jb      loc_C0007016
03:0011
03:0011 loc_C0007011: ; CODE XREF: start+19↓j
03:0011                 xor     bx, bx
03:0013                 xor     si, si
03:0015                 retn
03:0016
03:0016 loc_C0007016: ; CODE XREF: start+3↑j
03:0016 ; start+D↑j
03:0016                 mov     ax, 8001h
03:0019                 jmp     short loc_C0007011
03:0019 start           endp
```,
  caption: [16-bit initialization code fragment]
)

But the Device Declaration block stores in the 32-bit code objects.
The `Control_Proc` stores in the locked 32-bit code object. The `Dev_Init_Proc` and `V86_Proc` might be store in the 32-bit or 16-bit code objects.

As you see, no 286 Call Gate entries here because of Device driver API presented in the hidden Declaration block and VMM operates loaded driver using this table. The DDB Entry Point always be 32-bit entry because of near addresses of driver API stores together.

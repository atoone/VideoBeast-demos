# VideoBeast Demo Projects

These are short projects demonstrating or testing various VideoBeast features.

VideoBeast is a new 8-bit graphics chip for retro and homebrew computers. It provides
multiple layers, bitmap graphics, tiles, text, sprites and support for tricks like raster
effects at resolutions of up to 848 x 480, and 512 colours.

More details, including the current status and developer documentation are available here: https://feersumbeasts.com/videobeast.html.

# Compatible Systems

VideoBeast can be interfaced to many 8-bit computers. These demos were written specifically
to work with the MicroBeast and ZX Spectrum interface boards. There are separate top-level assembly 
files that take account of the differences in the systems.

ZX Spectrum demos are built and saved as `.TAP` files, which include a simple BASIC loader and
will run on the original Spectrum with a VideoBeast expansion.

MicroBeast demos are built as CP/M 2.2 `.COM` files and appended to a `demo_disk` disk image
file. This can be downloaded to the MicroBeast and the demos run from the command line.

# Building

Windows batch files are provided to build the demos. The following additional command line tools 
must be installed to complete the build:

 * `sjasmplus` The Sjasmplus cross compiler is used to create `.TAP` and CP/M `.COM` files. The current version is avaliable here: https://github.com/z00m128/sjasmplus
 * CPM Tools. These are used to create a MicroBeast compatible CP/M disk image. Pre-built Windows executables are availble here: https://www.cpm8680.com/cpmtools/ or the original source is available from http://www.moria.de/~michael/cpmtools/
 * Python. Some graphic conversions are carried out (to extract tiles and sprites from image files) with Python scripts in the `\common` directory.
 * ZX0. This is a fantastic utility that provides optimal compression for 8-bit systems (and in particular the Z80). The compressor and source for decompression are available here: https://github.com/einar-saukas/ZX0

Note that `.txm` tile maps were generated with Pro Motion NG from https://www.cosmigo.com/

# Notes on Code

VideoBeast occupies up to 16KB of memory in the host system, with the majority of this area used to write graphics to video RAM. The top few bytes act
as registers that allow layers, palettes and other features to be configured. VideoBeast has 1MB of RAM for graphics data, so the registers include
a set of page registers that map the 16KB address area into one or more areas of video RAM. Labels for common registers are defined in `\common\videobeast.inc`.

Since VideoBeast itself may be mapped to different memory addresses on different host systems, `\common\videobeast.inc` requires that the label
`VBASE` has been set to the correct base address for the system being targetted before it is included.

Most of the demos have a host-specific main assembly file that configures the system for access to VideoBeast, and then calls the main demo 
routines contained in shared system-independent files.

## MicroBeast

MicroBeast has a simple memory banking mechanism, with the Z80 address space split into four 16k banks that can be mapped to different physical
memory pages. Banks are configured by writing the physical page number to ports `070h..073h`. The VideoBeast interface card is at physical 
page `040h`, and demos typically map it to addresses `4000h..7FFFh` (ie. Bank 1). To map VideoBeast to Bank 1, the following assembly can be used:

```
LD      A, 040h
OUT     (71h), A
```

MicroBeast is a CP/M machine that loads `.COM` files to address `100h` for execution. When VideoBeast is plugged in, the CP/M BIOS automatically uses it
for the user console. To do so, it pages in VideoBeast to a memory bank whenever characters are written to console or under interrupt to update the 
cursor. Any user programs that wish to access VideoBeast must either disable interrupts and avoid system calls, or let the BIOS know which bank they
are using for VideoBeast.

The `MBB_GET_PAGE` and `MBB_SET_PAGE` BIOS routines (defined in `\common\bios_1_6.inc`) are used to ensure that the correct banks are mapped 
during program execution and when returning to CP\M. In addition, care must be taken to restore VideoBeast paging when returning to CP/M to ensure 
the console continues to function. Note that the BIOS assumes that VideoBeast is in a 'good' state when handling system calls.

## ZX Spectrum

The VideoBeast interface for the ZX Spectrum maps it in two places. One is 'under' the 8K range from 16384 to 24576 that includes the normal Spectrum 
screen area. On boot, this allows Spectrum screen writes to be translated into VideoBeast bitmap writes. The second is across the first 16K of the
address space, normally occupied by the Spectrum ROM. On boot this is area is disabled, but writes to the ROM area can be enabled (allowing VideoBeast registers to be updated whilst the Spectrum behaves normally), or the Spectrum ROM can be paged out completely to allow full read/write access to VideoBeast.

The interface card controls the mapping of VideoBeast with a register at port `23h` (`35` decimal). The port is defined as follows:

|  7   |   6   |  5   |   4   |  3   |   2   |  1   |   0   | 
| ---- | ----- | ---- | ----- | ---- | ----- | ---- | ----- |
|  -   | `SCR` | `ROM`| `RRD` |   <- | `VEC` | ->   | `INT` |

Screen-area writes are enabled when the `SCR` bit is set. ROM-area writes are set when the `ROM` bit is set, and the ROM is paged out completely when
the `RRD` (ROM-read) bit is set. VideoBeast may generate interrupts (not currently supported by the interface). These will enabled by setting the `INT` bit, when the 3-bit `VEC` value is then used as the interrupt vector.
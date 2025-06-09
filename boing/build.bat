REM Convert boing cells
REM Colour 14 as zero, raw binary, max of 156 cells, 4 bit output

..\common\tiler.py -x 14 -r -m 156 -4 ..\assets\boing_tiles.png boing_tiles.bin
zx0 boing_tiles.bin boing_tiles.zx0

REM Convert boing map - crop blank cells (ends up 15x13), write raw binary
..\common\cropper.py -r "..\assets\boing.map001.txm" boing_map.bin

REM CP/M build
sjasmplus --lst boing_cpm.asm

cd ..
cpmrm -f memotech-type50 demo_disk.img boing.com
cpmcp -f memotech-type50 demo_disk.img boing\boing.com 0:boing.com
cd boing

REM Spectrum build
sjasmplus --lst boing_zx.asm
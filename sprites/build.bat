sjasmplus --lst sprites_cpm.asm

cd ..
cpmrm -f memotech-type50 demo_disk.img sprites.com
cpmcp -f memotech-type50 demo_disk.img sprites\sprites.com 0:sprites.com
cd sprites
from PIL import Image
import sys, getopt

def help():
    print ('tiler.py [-h] [-i] [-f] [-v] [-c cols] [-p prefix] [-s suffix] [-t terminator] [-l lineNo] [-x transparent] <input.png> <output>')
    print ('   -h : output hex values')
    print ("   -f : Use fast hex format")
    print ("   -r : write as raw binary")
    print ("   -t <nn> : use threshold when converting to single bit")
    print ("   -i : invert pixels")
    print ("   -4 : Output 4 bit pixels")
    print ("   -m <nn>: Output a maximum of <nn> cells")
    print ("   -x <nn>: move palette index <nn> to 0")
    print ("   -c <nn>: split lines at <nn> columns")
    print ("   -l <nn>: insert line numbers, starting at <nn>")
    print ("   -p <string>: use prefix at start of each line")
    print ("   -s <string>: append suffix at end of each line")
    print ("   -b <string>: use after -h or -f to set separator")
    print ("   -n <string>: use string format to write numbers (eg. \{:02X\})")
    print ("   -v : display image")

def writeByte(f, value):
    global bytesOut  
    global lineNumber

    if isRaw:  
        f.write(bytes([value]))
    else:
        if bytesOut != 0:
            f.write(separator)

        if isFast:
            f.write(chr(ord('a')+((value >> 4) & 0x0F)))
            f.write(chr(ord('a')+((value & 0x0f))))
        else:
            f.write(numFormat.format(value))

    bytesOut+=1
    if bytesOut % cols == 0 and not isRaw:
        f.write(suffix)
        f.write("\n")
        if lineNumber > 0:
            f.write("{} ".format(lineNumber))
            lineNumber += 10
        f.write(prefix)
        bytesOut = 0

try:
    opts, args = getopt.getopt(sys.argv[1:],"hif4rp:s:c:l:t:x:b:n:m:")
except getopt.GetoptError:
    help()
    sys.exit(2)

if len(args) < 1:
    help()
    sys.exit(2)

inputPng = args[0]
cols = 8
prefix = ""
suffix = ""
separator = ","
lineNumber = -1
isBit = True
isHex = False
isFast = False
invert = False
showImage = False
transparent = 999
threshold = 0
numFormat = "{}"
isRaw = False
maximum = 10000

for opt, arg in opts:
    if opt == '-h':
        isHex = True
        separator = ""
        numFormat = "{:02X}"
    if opt == '-f':
        isFast = True
        separator = ""
    if opt == '-v':
        showImage = True
    if opt == '-4':
        isBit = False
    if opt == '-r':
        isRaw = True
    elif opt == '-p':
        prefix = arg
    elif opt == '-s':
        suffix = arg
    elif opt == '-c':
        cols = int(arg)
    elif opt == '-i':
        invert = True
    elif opt == '-l':
        lineNumber = int(arg)
    elif opt == '-t':
        threshold = int(arg)
    elif opt == '-x':
        transparent = int(arg)
    elif opt == '-b':
        separator = arg
    elif opt == '-n':
        numFormat = arg
    elif opt == '-m':
        maximum = int(arg)


if len(args) < 2:
    help()
    sys.exit(2)


bytesOut = 0              # Data bytes written

with Image.open(inputPng) as im:
    if showImage:
        im.show()

    if im.width % 8 != 0:
        print("Width is not a multiple of 8")
        sys.exit()

    if im.height % 8 != 0:
        print("Height is not a multiple of 8")
        sys.exit()

    outputAsm = args[1]
    count = 0              # Number of tiles
    byteTotal = 0

    f = open(outputAsm, "w" if not isRaw else "wb")
    
    if lineNumber > 0:
        f.write("{} ".format(lineNumber))
        lineNumber += 10
                
    if not isRaw:
        f.write(prefix);

    for y in range(0, im.height, 8):
        for x in range(0, im.width, 8):
    
            count += 1

            for row in range(8):
                if isBit:
                    pixels = 0
                    for pixel in range(8):
                        idx = im.getpixel((x+pixel, y+row))
                        isSet = idx > threshold
                        if invert:
                            isSet = not isSet

                        if isSet:
                            pixels |= 1 << (7-pixel)

                    writeByte(f, pixels)
                    byteTotal+=1
                else:
                    for pixel in range(0, 8, 2):
                        idx1 = im.getpixel((x+pixel, y+row))
                        idx2 = im.getpixel((x+pixel+1, y+row))
                        if transparent != 999:
                            if idx1 == transparent:
                                idx1 = 0
                            else:
                                if idx1 < transparent:
                                    idx1 +=1

                            if idx2 == transparent:
                                idx2 = 0
                            else:
                                if idx2 < transparent:
                                    idx2 +=1
                        pixels = (idx1 & 0x0F) << 4 | (idx2 & 0x0F)
                        writeByte(f, pixels)
                        byteTotal+=1

            if count == maximum:
                break
        else: 
            continue         # This makes the break above break out of both loops
        break

    if bytesOut % cols != 0 and not isRaw:
        f.write(suffix)
        f.write("\n")

    f.close()

    print("Wrote a total of {} bytes for {} cells".format(byteTotal, count))
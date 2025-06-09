#
# Reads a TXM (Text tile map) file produced by ProMotion NG and outputs a cropped version with surrouding empty tiles removed
#
# Usage python cropper.py <input.txm> <output>
#
#
import sys, getopt

def help():
    print ('cropper.py [-h] [-i] [-c cols] [-p prefix] [-s suffix] [-t terminator] [-l lineNo] <input.txm> <output>')
    print ('   -h : output hex values')
    print ('   -r : output raw binary')
    print ('   -w : tile indices as words (over 255 tiles)')
    print ("   -i : show info only, don't write file")
    print ("   -a : use all map, don't crop")
    print ("   -c <nn>: split lines at <nn> columns")
    print ("   -l <nn>: insert line numbers, starting at <nn>")
    print ("   -p : use prefix at start of each line")
    print ("   -s : appens suffix at end of each line")
    print ("   -t : terminate each line with text")

try:
    opts, args = getopt.getopt(sys.argv[1:],"hifrwap:s:c:t:l:")
except getopt.GetoptError:
    help()
    sys.exit(2)

if len(args) < 1:
    help()
    sys.exit(2)

inputTxm = args[0]
cols = 999
prefix = ""
suffix = ""
terminator = ""
lineNumber = -1
dataWidth = 2
isHex = False
infoOnly = False
isFast = False
isRaw = False
useAll = False

for opt, arg in opts:
    if opt == '-h':
        isHex = True
    if opt == '-f':
        isFast = True
    elif opt == '-p':
        prefix = arg
    elif opt == '-s':
        suffix = arg
    elif opt == '-t':
        terminator = arg
    elif opt == '-c':
        cols = int(arg)
    elif opt == '-i':
        infoOnly = True
    elif opt == '-r':
        isRaw = True
    elif opt == '-a':
        useAll = True
    elif opt == '-w':
        dataWidth = 4
    elif opt == '-l':
        lineNumber = int(arg)


if len(args) < 2 and not infoOnly:
    help()
    sys.exit(2)


txmFile = open(inputTxm, "r")
lines = txmFile.readlines()

firstRow = 0
lastRow = 0
firstCol = 0
lastCol = 0

maxTile = 0
maxCol = 0
maxRow = 0

for line in lines:
    values = line.split(",")
    allZero = True

    if len(values) > maxCol:
        maxCol = len(values)

    col = 0
    for value in values:
        isZero = int(value) == 0
        if int(value) > maxTile:
            maxTile = int(value)

        if not isZero:
            allZero = False
            if col > lastCol:
                lastCol = col 
            if firstCol == 0 or firstCol > col:
                firstCol = col 

        col+=1

    if not allZero:
        lastRow = maxRow
        if firstRow == 0:
            firstRow = maxRow 

    maxRow+=1

print( "Original dimensions are {} x {} (width, height)".format(maxCol, maxRow))
print( "Bounds are left, right: {},{} top, bottom: {},{}".format(firstCol, lastCol, firstRow, lastRow))
print( "Width {}, height {}".format(lastCol-firstCol+1, lastRow-firstRow+1))
print( "Maximum tile index (tiles-1) is {}".format(maxTile))

if infoOnly:
    exit(2) 

outputAsm = args[1]

row = 0

out = open(outputAsm, "w" if not isRaw else "wb")

numFormat = "{{:0{}X}}".format(dataWidth) if isHex else "{}"

if useAll:
    firstRow = 0
    lastRow = maxRow
    firstCol = 0
    lastCol = maxCol
    print( "Using original dimensions")


for line in lines:
    if row>=firstRow and row<=lastRow:
        values = line.split(",")
        col = 0
        idx = 0

        if not isRaw:
            if lineNumber > 0:
                out.write("{} ".format(lineNumber))
                lineNumber += 10
            out.write(prefix)

        for value in values:
            if col>=firstCol and col<=lastCol:
                if idx >= cols and not isRaw:
                    out.write(suffix)
                    out.write("\n")
                    if lineNumber > 0:
                        out.write("{} ".format(lineNumber))
                        lineNumber += 10
                    out.write(prefix)
                    idx=0

                val = int(value)

                if isRaw:  
                    if dataWidth > 2:
                        out.write(bytes([val & 0x0FF]))
                        val = (val >> 8) & 0x0FF

                    out.write(bytes([val]))
                else:
                    if col > firstCol and not (isHex or isFast):
                        out.write(",")
                    if isFast:
                        if dataWidth > 2:
                            out.write(chr(ord('a')+((val >> 12) & 0x0F)))
                            out.write(chr(ord('a')+((val>> 8) & 0x0f)))

                        out.write(chr(ord('a')+((val >> 4) & 0x0F)))
                        out.write(chr(ord('a')+((val & 0x0f))))
                    else:
                        out.write(numFormat.format(val))

                idx+=1

            col+=1

        if not isRaw:
            out.write(terminator)
            out.write(suffix)

            out.write("\n")
    row+=1

out.close()
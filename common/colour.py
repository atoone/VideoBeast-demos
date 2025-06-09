import sys, re

value = int(re.sub('#', '', sys.argv[1]), 16)

red   = round(((value >> 16) & 0x0FF) / (255 / 7.0))
green = round(((value >> 8) & 0x0FF) / (255 / 7.0))
blue  = round((value &0x0FF) / (255 / 7.0))

print("RGB {} {} {}".format(red, green, blue))

packed = (red << 12) | (green << 7) | (blue << 2)

print("Packed {:04X}".format(packed))
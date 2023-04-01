import tilengine
import std/streams
import strutils

const PAL64VER = 2.uint8

type
    paletteType = enum
        RGB332,
        RGB323,
        RGB233,
        CPC,
        SMS,
        FIVELEVELS,
        WEB,
        MEGADRIVE,
        AMIGA,
        SNES,
        DS,
        RGB24,
        NES

# We store the NES palette in a lookup table, because the way the NES Palette works is weird
var nesLUT = @[5592405.uint32, 6003, 1926, 3016056, 5833293, 7471121, 7208960, 4982784, 1514240, 10752, 12544, 11784, 9797, 0, 0, 0, 10855845, 22470, 2244581, 7219417, 11410086, 13768537, 13705479, 10958592, 6508800, 1599232, 29184, 29489, 27268, 0, 0, 0, 16711679, 3123455, 6128127, 10252543, 16216831, 16742333, 16744053, 16747051, 13475840, 8501250, 4048944, 1232251, 902608, 3947580, 0, 0, 16711679, 10804991, 11651327, 13418239, 16040703, 16762346, 16762825, 16764330, 15718038, 13688981, 11790245, 10480323, 10152166, 11513775, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

proc loadNESPal*(path: string): void =
    let
        file = open(path)
        fSize = file.getFileSize()
        fs = newFileStream(file)
    defer: fs.close()
    var data = newSeq[uint8](fSize)
    discard fs.readData(data[0].addr, sizeof(uint8) * data.len)

    for i in countup(0, nesLUT.len-1):
        if(i >= data.len div 3):
            var j = i * 3
            var msb = data[j]
            var mid = data[j + 1]
            var lsb = data[j + 2]
            var colVal = (msb.uint32 shl 16) or (mid.uint32 shl 8) or lsb.uint32
            nesLUT[i] = colVal
        else:
            nesLUT[i] = 0

proc loadHEXtoNES*(path: string): void =
    let
        file = open(path)
    defer: file.close()
    for i in countup(0, nesLUT.len-1):
        if not file.endOfFile():
            nesLUT[i] = parseHexInt(file.readLine()).uint32
        else:
            nesLUT[i] = 0

const cpcLut: array[3, byte] = [0.uint8, 128, 255]
# Converts to RGB24
proc bin2rgb(bin: uint32, palType: paletteType): uint32 =
    var
        r: uint32 = 0
        g: uint32 = 0
        b: uint32 = 0
    case palType
        of RGB332: # RGB 3-3-2
            # We calculate each RGB component
            r = ((bin shr 5 and 0b00000111).float32 * 36.42).uint32 # we shift the bits to the right to get only 3 bits, then we multiply by 36.42 because 255/7 = 36.42
            g = ((bin shr 2 and 0b00000111).float32 * 36.42).uint32
            b = (bin and 0b00000011) * 85 # 255 / 3 = 85 per step (from 0 to 3, so 4 levels that covers 2 bits)
        of RGB323: # RGB 3-2-3
            # We calculate each RGB component
            r = ((bin shr 5 and 0b00000111).float32 * 36.42).uint32 # we shift the bits to the right to get only 3 bits, then we multiply by 36.42 because 255/7 = 36.42
            g = ((bin shr 3 and 0b00000111) * 85).uint32
            b = (((bin and 0b00000111).float32) * 36.42).uint32 # 255 / 3 = 85 per step (from 0 to 3, so 4 levels that covers 2 bits)
        of RGB233: # RGB 2-3-3
            # We calculate each RGB component
            r = ((bin shr 6 and 0b00000111).float32 * 85).uint32 # we shift the bits to the right to get only 3 bits, then we multiply by 36.42 because 255/7 = 36.42
            g = ((bin shr 3 and 0b00000111).float32 * 36.42).uint32
            b = ((bin and 0b00000011).float32 * 36.42).uint32 # 255 / 3 = 85 per step (from 0 to 3, so 4 levels that covers 2 bits)
        of CPC:
            r = cpcLut[bin shr 4]
            g = cpcLut[bin shr 2]
            b = cpcLut[bin and 0b11]
        of SMS: # SMS
            r = (bin shr 4 and 0b00000011) * 85
            g = (bin shr 2 and 0b00000011) * 85
            b = (bin and 0b00000011) * 85
        of FIVELEVELS: # 5 Levels
            r = (bin shr 6 and 0b0000000000000111) * 63 # Each component is encoded with 3 bits. Then 255/4 = 63.75 per step and we floor it. (from 0 to 4, so, 5 levels)
            g = (bin shr 3 and 0b0000000000000111) * 63
            b = (bin and 0b0000000000000111) * 63
        of WEB: # WEB
            r = (bin shr 6 and 0b0000000000000111) * 51 # Each component is encoded with 3 bits. Then 255/5 = 63.75 per step and we floor it. (from 0 to 5, so, 6 levels)
            g = (bin shr 3 and 0b0000000000000111) * 51
            b = (bin and 0b0000000000000111) * 51
        of MEGADRIVE: # MegaDrive
            r = (bin shr 6 and 0b0000000000000111) * 36 # Each component is encoded with 3 bits. Then 255/7 = 36.42 per step and we floor it. (from 0 to 7, so, 8 levels)
            g = (bin shr 3 and 0b0000000000000111) * 36
            b = (bin and 0b0000000000000111) * 36
        of AMIGA: # Amiga
            r = (bin shr 8 and 0b0000000000001111) # Each component is encoded with 4 bits.
            # echo bin.toHex()
            r = r or (r shl 4) # But I copy the low significant bits to the most significants bits to cover a full byte
            g = (bin shr 4 and 0b0000000000001111)
            g = g or (g shl 4)
            b = (bin and 0b0000000000001111)
            b = b or (b shl 4)
        of SNES: # SNES
            r = (bin shr 10 and 0b0000000000011111) * 8 # Each component is encoded with 5 bits. Then 255/31 = 8,22 per step and we floor it. (from 0 to 31, so, 32 levels)
            g = (bin shr 5 and 0b0000000000011111) * 8
            b = (bin and 0b0000000000011111) * 8
        of DS:
            r = (bin shr 12 and 0b111111) * 4 # Each component is encoded with 6 bits. Then 255/63 = 4.04 per step and we floor it. (from 0 to 63, so, 64 levels)
            g = (bin shr 6 and 0b111111) * 4
            b = (bin and 0b111111) * 4
        of RGB24:
            r = bin shr 16 and 0xFF # This is just the RGB format that everyone use...
            g = bin shr 8 and 0xFF
            b = bin and 0xFF
        of NES:
            return nesLUT[bin].uint32
        else:
            echo "Not supported!"
            return 0
    return ((r shl 16) or (g shl 8) or b) # Then, we convert separate RGB components to a single unsigned integer.

# Loads the PAL64 and sets into Tilengine's global palettes
proc loadPalsAndSet*(path: string, importEmbeddedNes: bool = false): void =
    let
        file = open(path)
        fSize = file.getFileSize()
        fs = newFileStream(file)
    defer: fs.close()

    # Data of the palettes
    var data = newSeq[uint8](fSize)
    
    # Reading the data of file and put it into the data buffer
    var i = fs.readData(data[0].addr, sizeof(uint8) * data.len)

    # Header and version checks
    var str = data[0].char & data[1].char & data[2].char & data[3].char & data[4].char
    var index = 5
    if(str != "PAL64"):
        echo "Invalid PAL64 format!!"
        return
    var myVer = data[index] and 0b01111111
    if(myVer > PAL64VER):
        echo "PAL64 version too new!!!"
        return
    if(myVer < 2):
        myVer += 3

    # Is the NES palette embedded in the file?
    var isNesEmbedded = data[index] shr 7
    inc index

    # Length of the palettes
    let len = data[index]
    inc index

    # Number of palettes
    var numPal = data[index]

    # Tilengine supports up to 8 palettes. So we clip this number.
    if(numPal > 8):
        numPal = 8

    # Global palettes initialization and setup
    var pal0 = createPalette(len.int)
    var pal1 = createPalette(len.int)
    var pal2 = createPalette(len.int)
    var pal3 = createPalette(len.int)
    var pal4 = createPalette(len.int)
    var pal5 = createPalette(len.int)
    var pal6 = createPalette(len.int)
    var pal7 = createPalette(len.int)

    setGlobalPalette(0, pal0)
    setGlobalPalette(1, pal1)
    setGlobalPalette(2, pal2)
    setGlobalPalette(3, pal3)
    setGlobalPalette(4, pal4)
    setGlobalPalette(5, pal5)
    setGlobalPalette(6, pal6)
    setGlobalPalette(7, pal7)

    index.inc

    # Getting the type of the palette (RGB 3-3-2, SMS, WEB Safe, MegaDrive, Amiga or SNES)
    let palType = data[index].paletteType

    index.inc

    # To know how much bytes a color uses.
    var bytes = 1
    var bgColor = 0.uint32

    # Applying the palettes
    for i in countup(0, (len.int * numPal.int)-1):
        var indexCol = i.uint32 mod (len)
        var palId = i div len.int
        var color: uint32 = 0
        if(palType < FIVELEVELS or palType == NES):
            color = bin2rgb(data[index + i].uint32, palType)
            bgColor = bin2rgb(data[index].uint32, palType)
            bytes = 1
        elif(palType != DS and palType != RGB24):
            var j = i * 2
            var msb = data[index + j]
            var lsb = data[index + j + 1]
            color = bin2rgb((msb.uint32 shl 8) or lsb.uint32, palType)
            bgColor = bin2rgb((data[index].uint32 shl 8) or data[index + 1].uint32, palType)
            bytes = 2
        else:
            var j = i * 3
            var msb = data[index + j]
            var mid = data[index + j + 1]
            var lsb = data[index + j + 2]
            var colVal = (msb.uint32 shl 16) or (mid.uint32 shl 8) or lsb.uint32
            color = bin2rgb(colVal, palType)
            bgColor = bin2rgb((data[index].uint32 shl 16) or (data[index + 1].uint32 shl 8) or data[index + 2], palType)
            bytes = 3
        getGlobalPalette(palId).setColor(indexCol.int, cast[uint8]((color shl 16) and 0xFF), cast[uint8]((color shl 8) and 0xFF), cast[uint8](color and 0xFF))

    index = index + (len.int * bytes * 8.int)
    
    # We load the embedded NES palette into the Lookup Table if the user wants and if it is a NES palette type
    if(isNesEmbedded.bool and palType == NES and importEmbeddedNes):
        for i in countup(0, nesLUT.len-1):
            var k = i * 3
            var msb = data[index + k] shl 16;
            var mid = (data[index + k + 1]) shl 8;
            var lsb = data[index + k + 2];
            nesLUT[i] = msb or mid or lsb
    setBgColor(cast[uint8]((bgColor shl 16) and 0xFF), cast[uint8]((bgColor shl 8) and 0xFF), cast[uint8](bgColor and 0xFF))

proc loadPalsAndGet*(path: string): seq[Palette] =
    let
        file = open(path)
        fSize = file.getFileSize()
        fs = newFileStream(file)
    defer: fs.close()
    var data = newSeq[uint8](fSize)
    var palSeq = newSeq[Palette](8)
    var i = fs.readData(data[0].addr, sizeof(uint8) * data.len)
    var str = data[0].char & data[1].char & data[2].char & data[3].char & data[4].char
    var index = 5
    if(str != "PAL64"):
        echo "Invalid PAL64 format!!"
        return
    let len = data[index]

    # storing palettes into a sequence of TLN_Palette
    palSeq[0] = createPalette(len.int)
    palSeq[1] = createPalette(len.int)
    palSeq[2] = createPalette(len.int)
    palSeq[3] = createPalette(len.int)
    palSeq[4] = createPalette(len.int)
    palSeq[5] = createPalette(len.int)
    palSeq[6] = createPalette(len.int)
    palSeq[7] = createPalette(len.int)

    index.inc

    # Getting the type of the palette (RGB 3-3-2, SMS, WEB Safe, MegaDrive, Amiga or SNES)
    let palType = data[index].paletteType

    index.inc

    # Applying the palettes
    for i in countup(0, (len.int * 8)-1):
        var indexCol = i.uint32 mod (len)
        var palId = i div len.int
        var color: uint32 = 0
        if(palType < FIVELEVELS or palType == NES):
            color = bin2rgb(data[index + i].uint32, palType)
        elif(palType != DS and palType != RGB24):
            var j = i * 2
            var msb = data[index + j]
            var lsb = data[index + j + 1]
            color = bin2rgb((msb.uint32 shl 8) or lsb.uint32, palType)
        else:
            var j = i * 3
            var msb = data[index + j]
            var mid = data[index + j + 1]
            var lsb = data[index + j + 2]
            var colVal = (msb shl 16) or (mid shl 8) or lsb
            color = bin2rgb(colVal, palType)
        palSeq[palId].setColor(indexCol.int, cast[uint8]((color shl 16) and 0xFF), cast[uint8]((color shl 8) and 0xFF), cast[uint8](color and 0xFF))
    return palSeq

# Loads one palette depending of a given index
proc loadPalByIndex*(path: string, palIndex: uint8): Palette =
    if(palIndex > 7):
        echo "Invalid index! Max index is 7!"
        return nil

    let
        file = open(path)
        fSize = file.getFileSize()
        fs = newFileStream(file)
    defer: fs.close()
    var data = newSeq[uint8](fSize)
    var i = fs.readData(data[0].addr, sizeof(uint8) * data.len)
    var str = data[0].char & data[1].char & data[2].char & data[3].char & data[4].char
    var index = 5
    if(str != "PAL64"):
        echo "Invalid PAL64 format!!"
        return
    let len = data[index]

    # Global palettes initialization and setup
    var pal = createPalette(len.int)

    index.inc

    # Getting the type of the palette (RGB 3-3-2, SMS, WEB Safe, MegaDrive, Amiga or SNES)
    let palType = data[index].paletteType

    index.inc

    # Applying the palettes
    for i in countup(0, len.int-1):
        var indexCol = i.uint32 
        var color: uint32 = 0
        if(palType < FIVELEVELS or palType == NES):
            color = bin2rgb(data[index + i + (palIndex.int * len.int)].uint32, palType)
        elif(palType != DS and palType != RGB24):
            var j = i * 2
            var msb = data[index + j]
            var lsb = data[index + j + 1]
            color = bin2rgb((msb.uint32 shl 8) or lsb.uint32, palType)
        else:
            var j = i * 3
            var msb = data[index + j]
            var mid = data[index + j + 1]
            var lsb = data[index + j + 2]
            var colVal = (msb shl 16) or (mid shl 8) or lsb
            color = bin2rgb(colVal, palType)
        pal.setColor(indexCol.int, cast[uint8]((color shl 16) and 0xFF), cast[uint8]((color shl 8) and 0xFF), cast[uint8](color and 0xFF))
    return pal
import tilengine
import std/encodings

# Puts a single character on the given tilemap. Caution, your tilemap should have a tileset with ASCII characters. 
# If the characters table doesn't start at the 0th tile, you can pass an offset to this function.
proc putChar*(character: char, x: int, y: int, tilemap: Tilemap, offset: uint16 = 0): void =
    if(character.uint16 >= 32):
        echo(character.uint16)
        let tile = Tile(index: character.uint16 + offset + 1)
        tilemap.setTile(y, x, tile)

# Writes text on the given tilemap. Caution, your tilemap should have a tileset with ASCII characters. 
# If the characters table doesn't start at the 0th tile, you can pass an offset to this function.
proc putText*(text: string, x: int, y: int, tilemap: Tilemap, offset: uint16 = 0): void =
    var text = text.convert("IBM437", "UTF-8")
    var xTemp = x
    var yTemp = y

    for c in text:
        if(c.uint16 >= 32):
            putChar(c, xTemp, yTemp, tilemap, offset)
            inc xTemp
        if(c == '\n'):
            inc yTemp
            xTemp = x
        if(c == '\t'):
            putChar(' ', xTemp, yTemp, tilemap, offset)
            inc xTemp
            putChar(' ', xTemp, yTemp, tilemap, offset)
            inc xTemp

# Creates a Tilemap with a Tileset containing ASCII characters and sends you the tilemap.
proc createTextField*(sizeX: int, sizeY: int, textTileset: Tileset, offset: uint16 = 0): Tilemap =
    return createTilemap(sizeY, sizeX, nil, 0x000000, textTileset)

import tilengine

proc copyTilemapSectionFromTilemap*(destination: Tilemap, source: Tilemap, x, y, width, height : int, destX, destY: int) =
    let
        dw = destination.getCols
        dh = destination.getRows

        sw = source.getCols
        sh = source.getRows
    
    for j in countdown(height - 1, 0):
        for i in countdown(width - 1, 0):
            let
                myX = x + i
                myY = y + j

                myDx = destX + i
                myDy = destY + j
            
            if(myDx >= dw or myDy >= dh or myDx < 0): continue
            if(myDy < 0): break
            var tile = Tile()
            if(myX >= 0 and myX < sw and myY >= 0 and myY < sh):
                tile = source[myX, myY]
            destination[destX + i, destY + j] = tile
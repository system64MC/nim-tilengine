import tilengine

proc clearBitmap*(bitmap: Bitmap): void =
    for i in 0..bitmap.getWidth()-1:
        for j in 0..bitmap.getHeight()-1:
            bitmap.getData(i, j)[0] = 0
    return

proc drawRect*(bitmap: Bitmap, x: int, y: int, x2: int, y2: int): void =
    for i in x..x2:
        for j in y..y2:
            bitmap.getData(i, j)[0] = 1
    
    return

proc drawRectWH*(bitmap: Bitmap, x: int, y: int, w: int, h: int, stroke: uint = 0, strokeColor: uint8 = 1, color: uint8 = 1): void =
    # Drawing stroke
    if stroke > 0:
        # Top and bottom
        for i in x-(stroke.int div 2)..x+w+(stroke.int div 2)-1:
            for j in y-(stroke.int div 2)..(y+(stroke.int div 2)-1):
                if (i >= 0 and i < bitmap.getWidth()-1) and (j >= 0 and j < bitmap.getHeight()-1):
                    bitmap.getData(i, j)[0] = strokeColor
        for i in x-(stroke.int div 2)..x+w+(stroke.int div 2)-1:
            for j in y-(stroke.int div 2)+h..(h+y+(stroke.int div 2)-1):
                if (i >= 0 and i < bitmap.getWidth()-1) and (j >= 0 and j < bitmap.getHeight()-1):
                    bitmap.getData(i, j)[0] = strokeColor

        # Sides
        for i in x-(stroke.int div 2)..x-(stroke.int div 2)+stroke.int-1:
            for j in y+(stroke.int div 2)..y+h-(stroke.int div 2):
                if (i >= 0 and i < bitmap.getWidth()-1) and (j >= 0 and j < bitmap.getHeight()-1):
                    bitmap.getData(i, j)[0] = strokeColor
        for i in x-(stroke.int div 2)+w..x+w+(stroke.int div 2)-1:
            for j in y+(stroke.int div 2)..y+h-(stroke.int div 2):
                if (i >= 0 and i < bitmap.getWidth()-1) and (j >= 0 and j < bitmap.getHeight()-1):
                    bitmap.getData(i, j)[0] = strokeColor

    # Drawing Inside
    for i in x+(stroke.int div 2)..x+w.int-(stroke.int div 2)-1:
        for j in y+(stroke.int div 2)..y+(h.int-stroke.int div 2)-1:
            if (i >= 0 and i < bitmap.getWidth()-1) and (j >= 0 and j < bitmap.getHeight()-1):
                bitmap.getData(i, j)[0] = color
    
    return

# proc drawLine(bitmap: TLN_Bitmap, x: int, y: int, x2: int, y2: int): void =
#     let lineLength = sqrt(pow(x2.float - x.float, 2) + pow(y2.float - y.float, 2))
#     for i in 0..round(lineLength * sqrt(2.float64)).int:
#         var myX = round(x.float + (i.float / lineLength) * (x2.float - x.float)).int
#         var myY = round(y.float + (i.float / lineLength) * (y2.float - y.float)).int
#         if (myX >= 0 and myX < bitmap.getBitmapWidth()-1) and (myY >= 0 and myY < bitmap.getBitmapHeight()-1):
#             bitmap.getBitmapPtr(myX.int, myY.int)[] = 1
#     return



proc drawCircle*(bitmap: Bitmap, xc: int, yc: int, radius: int): void =
    var
        p = 1 - radius
        x: int
        y = radius
    
    for i in 0..y:
        bitmap.getData(xc+x, yc+y)[0] = 1
        bitmap.getData(xc-y, yc-x)[0] = 1
        bitmap.getData(xc+y, yc-x)[0] = 1
        bitmap.getData(xc-y, yc+x)[0] = 1
        bitmap.getData(xc+y, yc+x)[0] = 1
        bitmap.getData(xc-x, yc-y)[0] = 1
        bitmap.getData(xc+x, yc-y)[0] = 1
        bitmap.getData(xc-x, yc+y)[0] = 1
        if p > 0:
            p = p + 2 * (x + 1) + 1 - 2 * (y + 1)
            inc x
            dec y
        else:
            p = p + 2 * (x + 1) + 1
            inc x
            
proc drawLine*(bitmap: Bitmap, x: int, y: int, x2: int, y2: int, thickness: int = 0, color: uint8 = 1): void

proc drawCircleFill*(bitmap: Bitmap, centerX: int, centerY: int, radius: int, stroke: int = 0, strokeColor: uint8 = 1, color: uint8 = 1): void =
    if stroke > 0:
        bitmap.drawCircleFill(centerX, centerY, radius + stroke, color = strokeColor)
        
    var
        x = 0
        y = radius
        m = 5 - 4 * radius

    while (x <= y):
        bitmap.drawRectWH(x = centerX - x, y = centerY - y, w = ((centerX + x) - (centerX - x))+1, h = 1, color = color)
        bitmap.drawRectWH(x = centerX - y, y = centerY - x, w = ((centerX + y) - (centerX - y))+1, h = 1, color = color)
        bitmap.drawRectWH(x = centerX - y, y = centerY + x, w = ((centerX + y) - (centerX - y))+1, h = 1, color = color)
        bitmap.drawRectWH(x = centerX - x, y = centerY + y, w = ((centerX + x) - (centerX - x))+1, h = 1, color = color)

        # bitmap.drawLine(centerX - x, centerY - y, centerX + x, centerY - y)
        # bitmap.drawLine(centerX - y, centerY - x, centerX + y, centerY - x)
        # bitmap.drawLine(centerX - y, centerY + x, centerX + y, centerY + x)
        # bitmap.drawLine(centerX - x, centerY + y, centerX + x, centerY + y)

        if (m > 0):
            
            dec y
            m -= 8 * y;
        inc x
        m += 8 * x + 4

proc drawLine*(bitmap: Bitmap, x: int, y: int, x2: int, y2: int, thickness: int = 0, color: uint8 = 1): void =
    var
        x = x
        y = y
        dx = abs(x2 - x)
        dy = abs(y2 - y)
        sx = if x < x2: 1 else: -1
        sy = if y < y2: 1 else: -1
        err = dx - dy

    while x != x2 or y != y2:
        if(x > bitmap.getWidth() - 2 or y > bitmap.getHeight() - 2): break
        if(thickness < 1):
                bitmap.getData(x, y)[0] = color
        else:
            bitmap.drawCircleFill(x, y, thickness, color = color)
        var e2 = err shl 1
        if e2 > -dy:
            err -= dy
            x += sx
        if e2 < dx:
            err += dx
            y += sy

    if(thickness < 1):
            bitmap.getData(x, y)[0] = color
    else:
        bitmap.drawCircleFill(x, y, thickness, color = color)
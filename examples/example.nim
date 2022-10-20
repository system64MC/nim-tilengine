import tilengine

# Initialise the engine
let engine = init(400, 240, numLayers = 1, numSprites = 0, numAnimations = 0)

# Load a tilemap
let map = loadTilemap("assets/forest/map.tmx")

# Modify a tile
let (x, y) = (10'i32, 12'i32)
var tile = map.getTile(y, x)
tile.flipx = true
map.setTile(y, x, tile)

# Assign tilemap to layer
const layer = Layer(0)
layer.setTilemap(map)

# Create window and run game loop
createWindow()
while processWindow():
  drawFrame()

# Cleanup
map.delete()
deleteWindow()
deinit()

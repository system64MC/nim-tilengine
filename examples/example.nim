import tilengine

# Initialise the engine
let engine = init(400, 240, numlayers = 1, numsprites = 0, numanimations = 0)

# Load a tilemap
let fg = loadTilemap("assets/forest/map.tmx")

# Modify a tile
block:
  let x = 10'i32
  let y = 12'i32
  var (tile, _) = fg.getTile(y, x)
  tile.flipx = true
  tile.flipy = true
  fg.setTile(y, x, tile)

# Assign tilemap to layer
const layer = Layer(0)
layer.setTilemap(fg)

# Create window and run game loop
doAssert createWindow()

while processWindow():
  drawFrame()

# Cleanup
fg.delete()
deinit()

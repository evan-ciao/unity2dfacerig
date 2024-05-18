# INSTRUCTIONS ON USE
# just plug this bad boy in any directory and execute it

import os
import sys
import glob
from PIL import Image
from pathlib import Path

filename = "".join([i for i in Path(glob.glob("*.png")[0]).stem if not i.isdigit()]) + "atlas.png"
if os.path.isfile(filename):
    os.remove(filename)
    
images = []
for file in glob.glob("*.png"):
    image = Image.open(file)
    images.append(image)

widths, heights = zip(*(i.size for i in images))

grid_size = 1

while len(images) > (grid_size*grid_size):
    grid_size += 1
    
min_width = min(widths)
min_height = min(heights)

new_image = Image.new('RGBA', (min_width * grid_size, min_height * grid_size))

x_offset = 0
y_offset = 0

for y in range(grid_size):
    for x in range(grid_size):
        if (y * grid_size + x ) < len(images):
            new_image.paste(images[y * grid_size + x], (x_offset, y_offset))
        x_offset += min_width
    x_offset = 0
    y_offset += min_height

new_image_exif = new_image.getexif()
new_image_exif[264] = min_width     # cell width exif metadata
new_image_exif[265] = min_height    # cell height exif metadata

new_image.save(filename, exif=new_image_exif)

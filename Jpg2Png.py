import os
from PIL import Image

def Jpg2Png():
    for root, dirs, files in os.walk('./'):
        for file in files:
            if file.endswith('.jpg'):
                path = os.path.join(root, file)
                im = Image.open(path)
                im = im.convert('RGBA')
                os.remove(path)
                path = path.replace('.jpg', '.png')
                im.save(path)  

if __name__ == "__main__":
    Jpg2Png()
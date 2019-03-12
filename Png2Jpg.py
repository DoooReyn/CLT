import os
from PIL import Image

def Png2Jpg():
    for root, dirs, files in os.walk('./'):
        for file in files:
            if file.endswith('.png'):
                path = os.path.join(root, file)
                im = Image.open(path)
                im = im.convert('RGB')
                os.remove(path)
                path = path.replace('.png', '.jpg')
                im.save(path)  

if __name__ == "__main__":
    Png2Jpg()

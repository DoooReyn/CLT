# encoding=utf-8

import os
from PIL import Image

DIR_ROOT = os.path.dirname(os.path.abspath(__file__)) + "/Action"

'''
搜索文件，交给回调处理
'''
def walk(rootdir, call):
    for root, dirs, files in os.walk(rootdir):
        for filename in files:
            if filename == '.DS_Store':
                continue
            filepath = os.path.join(root, filename)
            call(filepath)


'''
自动批处理转换
'''
def convert(filepath):
    if filepath[-3:] != 'png':
        return
    print filepath
    img64 = Image.open(filepath)
    img32 = img64.convert("RGBA")
    img32.save(filepath)

if __name__ == '__main__':
    walk(DIR_ROOT, convert)
    os.system('pause')

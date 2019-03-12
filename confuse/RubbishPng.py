#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
import random
import shutil
import string
import traceback
from PIL import Image
from PIL import ImageDraw
from random_words import RandomWords
from ConfuseConstant import CONFUSE_CONSTANT

abspath     = os.path.abspath
joinpath    = os.path.join
existpath   = os.path.exists
isdirpath   = os.path.isdir
isfilepath  = os.path.isfile
CONFUSE_TAG = CONFUSE_CONSTANT['RUBBISH_PNG_PREFIX']


class RubbishPng():
    
    def __init__(self):
        self.min_width = 4
        self.max_width = 16
        self.min_height = 4
        self.max_height = 16


    def reset(self, path):
        try:
            for root, dirs, files in os.walk(path):
                for file in files:
                    if file[2:5] == CONFUSE_TAG:
                        del_file = joinpath(root, file)
                        os.remove(del_file)
                        # print('remove file[ %s ] successfully.' % del_file)
        except Exception, e:
            traceback.print_exc()
        print('remove done!')


    def random_png(self, dirpath, num):
        for i in range(1, num+1):
            width  = random.randint(self.min_width, self.max_width)
            height = random.randint(self.min_height, self.max_height)

            img = Image.new('RGBA', (width, height), (255, 255, 255, 255))
            draw = ImageDraw.Draw(img)

            offx = random.randint(self.min_width, 255)
            offy = random.randint(self.min_height, 255)
            bitb = random.randint(10, 255)
            bita = random.randint(100, 255)
            for x in range(width):
                for y in range(height):
                    draw.point((x, y), fill=(x+offx,y+offy,bitb,bita))

            words = RandomWords().random_words(count=2)
            prefix = ''.join(random.sample(string.ascii_uppercase, 2))
            file = '%s/%s%s%s_%s.png' % (dirpath, prefix, CONFUSE_TAG, words[0], words[1])
            img.save(file, 'png')
            # print('save file[ %s ] successfully' % file)


    def generate(self, path):
        print('generate : ', path)
        for root, dirs, files in os.walk(path):
            for name in dirs:
                dirpath = joinpath(root, name)
                dirs = os.listdir( dirpath )
                filenums = 0
                for file in dirs:
                    filename = joinpath(dirpath, file)
                    if isfilepath(filename):
                        filenums += 1
                print 'generate %d files in %s' % ( filenums, dirpath )
                self.random_png(dirpath, filenums)
        print('generate done ! ')


    def run(self):
        path = CONFUSE_CONSTANT['CONFUSED_RESOURCE_PATH']
        self.reset(path)
        self.generate(path)


if __name__ == '__main__':
    RubbishPng().run()
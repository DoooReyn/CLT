#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
from xml.etree import ElementTree

class EffectExport:
    def __init__(self):
        self.__respath__  = '../res/Textures/Effect/'
        self.__savepath__ = '../EffectExport.txt'
        self.__effects__  = []

    def export_effect_files(self):
        for root, dirs, files in os.walk(self.__respath__):
            for file in files:
                filename, extname = os.path.splitext(file)
                if extname and extname == '.plist':
                    self.read_effect_cfg(filename, os.path.join(root, file))
    
    def tree_to_dict(self, tree):
        d = {}
        for index, item in enumerate(tree):
            if item.tag == 'key':
                if tree[index+1].tag == 'string':
                    d[item.text] = tree[index + 1].text
                elif tree[index + 1].tag == 'true':
                    d[item.text] = True
                elif tree[index + 1].tag == 'false':
                    d[item.text] = False
                elif tree[index+1].tag == 'dict':
                    d[item.text] = self.tree_to_dict(tree[index+1])
        return d

    def read_effect_cfg(self, basename, plist):
        root = ElementTree.fromstring(open(plist, 'r').read())
        plist_dict = self.tree_to_dict(root[0])
        frame_nums = str(len(plist_dict['frames']))
        print basename, frame_nums
        self.__effects__.append(basename + ' ' + frame_nums + '\n')

    def write_effect_cfg(self):
        with open(self.__savepath__, 'w') as f:
            f.writelines(self.__effects__)
            # for line in self.__effects__:

    def export(self):
        self.export_effect_files()
        self.write_effect_cfg()

if __name__ == '__main__':
    EffectExport().export()
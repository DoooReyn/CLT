# !/usr/bin/python
# -*- coding: utf-8 -*-

#**********************************************#
# Third Party Dependencies:
#    · RandomWords
#       - pip install RandomWords
#**********************************************#

import os
import sys
import random
import shutil
from ConfuseMd5 import ConfuseMd5
from random_words import RandomWords, LoremIpsum
from ConfuseConstant import CONFUSE_CONSTANT
from RubbishPng import RubbishPng

def get_file_extension(filepath):
    return os.path.splitext(filepath)[-1]

def make_root(path):
    try:
        os.makedirs(path)
    except OSError:
        if not os.path.isdir(path):
            raise

class Confuse():
    def __init__(self):
        self.max_rubbish_scale     = CONFUSE_CONSTANT['MAX_RUBBISH_SCALE']
        self.max_rubbish_sentenses = CONFUSE_CONSTANT['MAX_RUBBISH_SENTENSES']
        self.original_res_path     = CONFUSE_CONSTANT['ORIGINAL_RESOURCE_PATH']
        self.original_src_path     = CONFUSE_CONSTANT['ORIGINAL_SOURCE_PATH']
        self.confused_out_path     = CONFUSE_CONSTANT['CONFUSED_LOCATED_PATH']
        self.confused_res_path     = CONFUSE_CONSTANT['CONFUSED_RESOURCE_PATH']
        self.confused_src_path     = CONFUSE_CONSTANT['CONFUSED_SOURCE_PATH']
        self.rubbish_file_exts     = CONFUSE_CONSTANT['RUBBISH_FILE_EXTENSIONS']
        self.confuse_md5_helper    = ConfuseMd5()
        self.mkdirs()

    def mkdirs(self):
        make_root(self.confused_out_path)
        make_root(self.confused_src_path)
        make_root(self.confused_res_path)

    def delete_rubbish_files(self):
        for root, _, files in os.walk(self.confused_res_path):
            for filename in files:
                filepath = os.path.join(root, filename)
                fileext  = get_file_extension(filepath)
                if fileext in self.rubbish_file_exts:
                    os.remove(filepath)

    def generate_rubbish_file(self, root):
        # print('Generating rubbish files at dirctory : ' + root)
        times = random.randint(1, self.max_rubbish_scale)
        for _ in range(0, times):
            ext = random.sample(self.rubbish_file_exts, 1)[0]
            name = RandomWords().random_word()
            filepath = os.path.join(root, name+ext)
            with open(filepath, 'w') as f:
                numbers = random.randint(1, self.max_rubbish_sentenses)
                sentences = LoremIpsum().get_sentences_list(numbers)
                f.writelines([s+'\n' for s in sentences])

    def remove_images_flag(self):
        for root, _, files in os.walk(self.confused_res_path):
            for filename in files:
                filepath = os.path.join(root, filename)
                fileext  = get_file_extension(filepath)
                if fileext in ['.png', '.jpg']:
                    self.confuse_md5_helper.remove(filepath)

    def confuse_resources(self):
        for root, _, files in os.walk(self.confused_res_path):
            for filename in files:
                filepath = os.path.join(root, filename)
                fileext  = get_file_extension(filepath)
                if fileext in ['.png', 'jpg']:
                    # self.generate_rubbish_file(os.path.dirname(filepath))
                    # self.confuse_md5_helper.add(filepath)
                    pass
        RubbishPng().run()

    def remove_lua_files(self):
        for root, _, files in os.walk(self.confused_src_path):
            for filename in files:
                if filename.endswith('.lua'):
                    filepath = os.path.join(root, filename)
                    os.remove(filepath)

    def encrypt_lua_files(self):
        print('Compiling sources ...')
        fmt = (self.confused_src_path, self.confused_src_path, CONFUSE_CONSTANT['SOURCE_ENCRYPT_KEY'], CONFUSE_CONSTANT['SOURCE_ENCRYPT_SIGN'])
        compile_cmd = 'cocos luacompile -s %s -d %s -e -k %s -b %s --disable-compile' % fmt
        os.system(compile_cmd)
        print('Compiling sources done!!!')

    def confuse_lua_files(self):
        parser_cmd  = 'lua parser.lua --start-confuse'
        os.system(parser_cmd)

    def confuse_sources(self):
        self.confuse_lua_files()
        self.encrypt_lua_files()
        self.remove_lua_files()

    def confuse(self):
        option = raw_input('--------------------------\n0.Exit program\n1.Confuse lua sources\n2.Confuse resources\nwhich one to excute: ')
        print('--------------------------')
        if option == '0':
            print('Exit program')
            sys.exit(0)
        elif option == '1':
            print('1.Confuse lua sources')
            shutil.rmtree(self.confused_src_path, False)
            shutil.copytree(self.original_src_path, self.confused_src_path)
            self.confuse_sources()
            self.confuse()
        elif option == '2':
            print('2.Confuse resources')
            copy = raw_input('copy resources? (y/n) \n')
            if copy == 'y':
                print('Copying resources, please wait a moment...')
                shutil.rmtree(self.confused_res_path, False)
                shutil.copytree(self.original_res_path, self.confused_res_path)
            else:
                print('Removing last rubbish files, please wait a moment...')
                self.delete_rubbish_files()
                self.remove_images_flag()
            print('Confusing resources now...')
            self.confuse_resources()
            print('Confusing resources done!!!')
            self.confuse()
        else:
            print('Please choose a listed option above!!!')
            self.confuse()


if __name__ == "__main__":
    Confuse().confuse()
#!/usr/bin/python
# -*- coding: utf-8 -*-

#######################################################################
# Purpose:
#   Add or remove a custom flag string to/from a PNG/JPG file without
#   ruining its original structure
# How To Use:
#   1. Modify 'walk_dir' in class 'BatchFlagUtil' to confirm which 
#      directory you want it to work
#   2. Modify 'batch_chars_prefix' in class 'BatchFlagUtil' to set a 
#      prefix
#   3. Modify 'batch_chars_total_len' in class 'BatchFlagUtil' to 
#      generate a fixed size of
#      random string
#   4. Call 'BatchFlagUtil().Start()' and enjoy it
#######################################################################

import os, sys
import random
import string

BATCH_FLAG_UTIL_OPTIONS = '''------------------------
-- 0. Exit
-- 1. Add Batch Flag
-- 2. Remove Batch Flag
------------------------
Which one to excute? '''


class BatchFlagUtil():
    
    def __init__(self):
        self.options = [
            '[0. Exit]',
            '[1. Add Batch Flag]',
            '[2. Remove Batch Flag]',
        ]
        self.walk_dir = './../res/Images/'
        self.options_title = BATCH_FLAG_UTIL_OPTIONS
        self.batch_chars_prefix = 'batch_'
        self.batch_chars_total_len = 20
        self.batch_chars_tail_len = self.batch_chars_total_len - len(self.batch_chars_prefix)

    def AddBatchFlagForImage(self):
        for root, dirs, files in os.walk(self.walk_dir):
            for file in files:
                if file.endswith('.png') or file.endswith('.jpg'):
                    path = os.path.join(root, file)
                    with open(path, 'rb') as f:
                        content = f.read()
                        total = len(content)
                        f.seek(total-self.batch_chars_total_len, 0)
                        tail = f.read()
                        has_batch_tail = tail.find(self.batch_chars_prefix) >= 0
                        batch_tail = ''.join(random.choice(string.ascii_letters) for x in range(self.batch_chars_tail_len))
                        batch_tail = self.batch_chars_prefix + batch_tail
                        print "filename: {0}   batched? [{1}]   flag: {2}".format(path, has_batch_tail, batch_tail)
                        if has_batch_tail:
                            with open(path, 'wb') as f:
                                f.write(content.replace(tail, batch_tail))
                        else:
                            with open(path, 'a+b') as f:
                                f.write(batch_tail)

    def RemoveBatchFlagForImage(self):
        for root, dirs, files in os.walk(self.walk_dir):
            for file in files:
                if file.endswith('.png') or file.endswith('.jpg'):
                    path = os.path.join(root, file)
                    with open(path, 'rb') as f:
                        content = f.read()
                        total = len(content)
                        f.seek(total-self.batch_chars_total_len, 0)
                        tail = f.read()
                        has_batch_tail = tail.find(self.batch_chars_prefix) >= 0
                        print "filename: {0}   batched? [{1}]   remove_flag: {2}".format(path, has_batch_tail, has_batch_tail and tail or 'null')
                        if has_batch_tail:
                            with open(path, 'wb') as f:
                                f.write(content.replace(tail, ''))

    def Start(self):
        print(self.options_title)
        option = raw_input()
        if option == '0':
            print('> Excute ' + self.options[int(option)])
            sys.exit()
        elif option == '1':
            print('> Excute ' + self.options[int(option)])
            self.AddBatchFlagForImage()
        elif option == '2':
            print('> Excute ' + self.options[int(option)])
            self.RemoveBatchFlagForImage()
        else:
            print('please choose a right option.')
            self.Start()


if __name__ == "__main__":
    BatchFlagUtil().Start()
    
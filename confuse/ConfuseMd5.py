# !/usr/bin/python
# -*- coding: utf-8 -*-

# ######################################################################
# Purpose:
#   Add or remove a custom flag string to/from a PNG/JPG file without
#   ruining its original structure
# How To Use:
#   1. Modify 'batch_chars_prefix' in class 'ConfuseMd5' to set a prefix
#   2. Modify 'batch_chars_total_len' in class 'ConfuseMd5' to  generate 
#      a fixed size of random string
# ######################################################################

import os, sys
import random
import string

class ConfuseMd5():
    def __init__(self):
        self.batch_chars_prefix = 'batch_'
        self.batch_chars_total_len = 20
        self.batch_chars_tail_len = self.batch_chars_total_len - len(self.batch_chars_prefix)

    def add(self, filepath):
        if filepath.endswith('.png') or filepath.endswith('.jpg'):
            with open(filepath, 'rb') as f:
                content = f.read()
                total = len(content)
                f.seek(total-self.batch_chars_total_len, 0)
                tail = f.read()
                has_batch_tail = tail.find(self.batch_chars_prefix) >= 0
                batch_tail = ''.join(random.choice(string.ascii_letters) for x in range(self.batch_chars_tail_len))
                batch_tail = self.batch_chars_prefix + batch_tail
                print "add: {0}  batched? [{1}]  flag: {2}".format(filepath, has_batch_tail, batch_tail)
                if has_batch_tail:
                    with open(filepath, 'wb') as f:
                        f.write(content.replace(tail, batch_tail))
                else:
                    with open(filepath, 'a+b') as f:
                        f.write(batch_tail)

    def remove(self, filepath):
        if filepath.endswith('.png') or filepath.endswith('.jpg'):
            with open(filepath, 'rb') as f:
                content = f.read()
                total = len(content)
                f.seek(total-self.batch_chars_total_len, 0)
                tail = f.read()
                has_batch_tail = tail.find(self.batch_chars_prefix) >= 0
                if has_batch_tail:
                    print "remove: {0}  batched? [{1}]  remove_flag: {2}".format(filepath, has_batch_tail, has_batch_tail and tail or 'null')
                    with open(filepath, 'wb') as f:
                        f.write(content.replace(tail, ''))

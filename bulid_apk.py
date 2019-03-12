#!/usr/bin/python
# -*- coding: UTF-8 -*-

import sys, getopt
import os

os.chdir(os.path.split(os.path.realpath(__file__))[0])
print '参数列表:', str(sys.argv)
print(sys.argv[1])
if sys.argv[1] == "release":
	os.system("cocos compile -p android --ap android-19 -m release")
else:
	os.system("cocos compile -p android --ap android-19 -m debug")
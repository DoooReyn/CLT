#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import types
from PIL import Image

dirname   = os.path.dirname
abspath   = os.path.abspath
relpath   = os.path.relpath
joinpath  = os.path.join
existpath = os.path.exists

CurDir  = dirname(abspath(__file__))
ResDir  = abspath(joinpath(CurDir, 'icon.png'))
ICON_SIZE = {
    'drawable-ldpi' : 32,
    'drawable-mdpi' : 48,
    'drawable-hdpi' : 72,
    'drawable-xhdpi' : 96,
    'drawable-xxhdpi' : 144,
    'drawable-xxxhdpi' : 192
}

for k, v in ICON_SIZE.items():
    img = Image.open(ResDir)
    out = img.resize((v,v), Image.ANTIALIAS)
    ico = abspath(joinpath(CurDir, k))
    if not existpath(ico):
        os.mkdir(ico)
    out.save(joinpath(ico, 'icon.png'))

os.system('pause')

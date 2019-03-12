#!/usr/bin/python
# -*- coding: utf-8 -*-

import os, sys
import qrcode
import random

QR_DATA = 'http://m.wldf.zqgame.com'
QR_FILE = './QRCode.png'
QR_SIZE = (128,128)

def GenerateQRcode():
    qr = qrcode.QRCode(
        version=None,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=4,
        border=2,
    )
    qr.add_data(QR_DATA)
    qr.make(fit=True)
    img = qr.make_image().resize(QR_SIZE)
    img.save(QR_FILE)


if __name__ == "__main__":
    GenerateQRcode()
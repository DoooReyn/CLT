# encoding=utf-8

import os, chardet, codecs

SRC_ROOT = '../src/'
Oops = []
IgnoreEN = ['ISO-8859-1', 'utf-8', 'ascii']

def detect_file_encoding(fp):
    en = None
    ct = None
    with open(fp, 'rb+') as f:
        ct = f.read()
        en = chardet.detect(ct)['encoding']

    ok = en in IgnoreEN
    print(ok, en, fp)

    if not ok:
        collectOops("%s's encoding is %s" % (fp, en))
        s = ct.decode(en, errors='ignore')
        if en == 'UTF-8-SIG':
            collectOops('trying to convert encoding from %s to utf-8' % en)
            with open(fp, 'wb') as f:
                f.write(s.encode('utf-8', errors='ignore'))

def collectOops(oops):
    Oops.append(oops)

def dumpOops():
    if len(Oops) == 0:
        return
    print('\n---Oops---')
    for i, item in enumerate(Oops):
        print('[%d] %s' %(i, item))

def walk(path):
    for root, dirs, files in os.walk(path):
        for file in files:
            fp = os.path.join(root, file)
            try:
                detect_file_encoding(fp)
            except:
                print('%s detect failed' % fp)

def detect():
    walk(SRC_ROOT)
    dumpOops()
    print('\n---Done---')
    return len(Oops) == 0

if __name__ == '__main__':
    detect()


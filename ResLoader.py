# encoding=utf-8

import os, sys, json, types
IS_WINOS = True
DIR_ROOT = os.path.dirname(os.path.abspath(__file__))
DIR_RES  = os.path.join(DIR_ROOT, '../res/')
RES_SKIP = ['csb', 'Map/Block', 'UI', 'Proto']
RES_JSON = os.path.join(DIR_ROOT, '../src/game/Resources.json')
RES_LUA  = os.path.join(DIR_ROOT, '../src/game/Resources.lua')
RES_DICT = {}
SORT_TYPE = {
    # "png"  : "image",
    # "jpg"  : "Image",
    # "fnt"  : "fnt",
    "plist": "animate",
    # "tmx"  : "map",
    # "pb"   : "proto",
    # "mp3"  : "sound",
    # "csb"  : "csb",
    "sheet": "texture",
    # "json" : "jsonfont"
}

'''
调用资源处理方法
拆分方式：字体、图片、图集、地图、帧动画、Proto
'''
def callRes(filepath):
    if filepath[-4:] == '.ccz':
        return

    if filepath.find(' ') != -1:
        return

    rename = filepath[::]
    if IS_WINOS:
        rename = rename.replace('\\', '/')

    for item in RES_SKIP:
        if rename.find(item) != -1:
            if filepath[-6:] == '.plist':
                print("skip " + filepath.replace(DIR_RES, ''))
                break
            return

    base = os.path.basename(rename)
    head = base.split('.')[0]
    ext  = base.split('.')[1]
    path = filepath.replace(DIR_RES, '')
    if IS_WINOS:
        sort = path.split('\\')[0]
    else:
        sort = path.split('/')[0]

    if ext == 'plist' and sort.find('.plist') != -1:
        # print("!!!", base)
        sort = ext = 'sheet'
    sort_type = SORT_TYPE.get(ext)

    if not sort_type:
        # print(ext, sort)
        return

    if IS_WINOS:
        path = path.replace('\\', '/')

    RES_DICT[head] = path


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
写入资源文件
'''
def writeResJson():
    with open(RES_LUA, 'w') as f:
        f.write('return {\n')
        for v in RES_DICT:
            f.write('\t["%s"] = "%s",\n' % (v, RES_DICT[v]))
        f.write('}\n')
        print('Done! \nJson file saved at : ' + os.path.abspath(RES_LUA))


if __name__ == '__main__':
    walk(DIR_RES, callRes)
    writeResJson()
    os.system('pause')
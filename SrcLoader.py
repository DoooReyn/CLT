# encoding=utf-8

import os
from RxPlatform import RxPlatform

DIR_ROOT = os.path.dirname(os.path.abspath(__file__)) + '/../'
DIR_SRC  = os.path.join(DIR_ROOT, 'src/')
DIR_APP  = os.path.join(DIR_ROOT, 'src/game/')
SRC_LUA  = os.path.join(DIR_ROOT, 'src/game/Sources.lua')
SRC_DICT = {}

print('DIR_ROOT : ' + DIR_ROOT)
print('DIR_SRC  : ' + DIR_SRC )
print('DIR_APP  : ' + DIR_APP )
print('SRC_LUA  : ' + SRC_LUA )

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
调用源码处理方法
拆分方式：配置、数据、管理器、UI、其他
'''
def callSrc(filepath):
    if filepath[-3:] != 'lua':
        return
    if filepath.find('Game.lua') != -1:
        return

    app_rel_path  = filepath.replace(DIR_SRC, '').replace('.lua', '').replace(RxPlatform().getOsSep(), '.')
    app_rel_path  = app_rel_path.replace('/', '.')
    app_base_name = os.path.basename(filepath).replace('.lua', '')
    SRC_DICT[app_base_name] = app_rel_path
    
TAIL = '''
cc.exports.include = function(source)
	if not Sources[source] then
		printInfo("!!! lua file '%s' not found.", source)
		return nil
	end
	return require(Sources[source])
end
'''

'''
写入源码文件
'''
def writeSrcJson():
    with open(SRC_LUA, 'w') as f:
        f.write('local Sources = {\n')
        for v in SRC_DICT:
            f.write("\t%s = '%s',\n" % (v, SRC_DICT[v]))
        f.write('}\n')
        f.write(TAIL)
        print('Done! \nJson file saved at : ' + os.path.abspath(SRC_LUA))

if __name__ == '__main__':
    walk(DIR_APP, callSrc)
    writeSrcJson()
    os.system('pause')

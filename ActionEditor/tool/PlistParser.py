#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import re
import json
import codecs
import types
import shutil
from numbers import *
import xml.etree.ElementTree as ET
from AnimationConstants import ANIMATION_CONSTANTS

## 空格
def space_str(layer):
    	spaces = ""
	for i in range(0,layer):
		spaces += '\t'
	return spaces


## 字典转Lua表
def dic_to_lua_str(data,layer=0):
	d_type = type(data)
	if  d_type is types.StringTypes or d_type is str or d_type is types.UnicodeType:
		yield ("'" + data + "'")
	elif d_type is types.BooleanType:
		if data:
			yield ('true')
		else:
			yield ('false')
	elif d_type is types.IntType or d_type is types.LongType or d_type is types.FloatType:
		yield (str(data))
	elif d_type is types.ListType:
		yield ("{\n")
		yield (space_str(layer+1))
		for i in range(0,len(data)):
			for sub in  dic_to_lua_str(data[i],layer+1):
				yield sub
			if i < len(data)-1:
				yield (',\n' + space_str(layer+1))
                # yield (space_str(layer))
		yield ('\n')
		yield (space_str(layer))
		yield ('}')
	elif d_type is types.DictType:
		yield (space_str(layer))
		yield ("{\n")
		data_len = len(data)
		data_count = 0
		for k,v in data.items():
			data_count += 1
			yield (space_str(layer+1))
			yield ('[\'' + str(k) + '\']')
			yield (' = ')
			try:
				for sub in  dic_to_lua_str(v,layer +1):
					yield sub
				if data_count < data_len:
					yield (',\n')

			except Exception, e:
				print 'error in ',k,v
				raise
		yield ('\n')
		yield (space_str(layer))
		yield ('}')
	else:
		raise d_type , 'is error'


## Json转Lua表
def str_to_lua_table(jsonStr):
	data_dic = None
	try:
		data_dic = json.loads(jsonStr)
	except Exception, e:
		data_dic =[]
	else:
		pass
	finally:
		pass
	bytes = ''
	for it in dic_to_lua_str(data_dic):
		bytes += it
	return bytes


## Json文件转Lua文件
def file_to_lua_file(jsonFile,luaFile):
	with open(luaFile,'w') as luafile:
		with open(jsonFile) as jsonfile:
			luafile.write(str_to_lua_table(jsonfile.read()))


# 根据递归深度输出 制表符
def output_tab(depth, outputHandler):
    outputHandler.write('\t'*depth)


## 输出列表
def output_list(value, depth, outputHandler):
    val_len = len(value) - 1
    for index, val in enumerate(value):
        if isinstance(val, list):
            outputHandler.write('\t'*(depth+1) + '{')
            output_list(val, depth+1, outputHandler)
            if val_len == index:
                outputHandler.write('}\n')
            else:
                outputHandler.write('},\n')
        else:
            if val_len == index:
                if isinstance(val, str):
                    outputHandler.write('"' + str(val) + '"')
                else:
                    outputHandler.write(str(val))
            else:
                if isinstance(val, str):
                    outputHandler.write('"' + str(val) + '",')
                else:
                    outputHandler.write(str(val) + ',')


## 将字典递归转化输出
def recursive_serach_dict(depth, dic, outputHandler):
    for key, val in dic.items():
        # output key
        output_tab(depth, outputHandler)

        if isinstance(key, Number):
            outputHandler.write('[%s] = ' % str(key))
        elif isinstance(key, str):
            outputHandler.write('[\'%s\'] = ' % key)

        # output val
        if isinstance(val, dict):
            outputHandler.write('{\n')
            recursive_serach_dict(depth+1, val, outputHandler)
            output_tab(depth, outputHandler)
            outputHandler.write('},')
        elif isinstance(val, Number):
            outputHandler.write('%s,' % str(val))
        elif isinstance(val, str):
            outputHandler.write('\'%s\',' % val)
        elif isinstance(val, list):
            outputHandler.write('{\n')
            output_tab(depth-2, outputHandler)
            output_list(val, depth, outputHandler)
            output_tab(depth, outputHandler)
            outputHandler.write('},')
        outputHandler.write('\n')


## 将字典写入lua
def write_dict_lua(dict_tmp, table_name, file_path):
    if(type(dict_tmp) != dict):
        print("ERROR: only parse dict type!")
        return

    table_file_path = os.path.join(file_path, '%s.lua' % table_name)
    outputHandler = codecs.open(table_file_path, 'w', encoding='utf-8')

    outputHandler.write('local _M = {\n')
    # outputHandler.write('\t["texture"] = "%s",\n' % table_name)

    recursive_serach_dict(1, dict_tmp, outputHandler)

    outputHandler.write('}\n')
    outputHandler.write('\nreturn _M')
    outputHandler.close()


## XML转化为Dict
def tree_to_dict(tree):
    d = {}
    for index, item in enumerate(tree):
        if item.tag == 'key':
            tag = tree[index+1].tag
            if tag == 'string':
                ## 过滤掉 sourceColorRect 和 smartupdate，这两个字段无用
                if item.text in ['sourceColorRect', 'smartupdate']:
                    continue
                d[item.text] = tree[index+1].text
            elif tag == 'integer':
                d[item.text] = int(tree[index+1].text)
            elif tag == 'true':
                d[item.text] = True
            elif tag == 'false':
                d[item.text] = False
            elif tag == 'dict':
                d[item.text] = tree_to_dict(tree[index+1])
            elif tag == 'array':
                ## 主要是 aliases 字段
                d[item.text] = 'array'
            else:
                print('=>', index, item.tag, item.text)
    return d


## Dict转化为XML
def dict_to_tree(d, depth=0):
    depth = 0
    l = []
    for index, item in d.iteritems():
        if isinstance(item, dict):
            l.append(depth*'\t' + '<key>%s</key>\n' % (index))
            l.append(depth*'\t' + '<dict>\n')
            l.append(''.join(dict_to_tree(item, depth+1)))
            l.append(depth*'\t' + '</dict>\n')
        elif isinstance(item, bool):
            if item == True:
                l.append(depth*'\t' + '<key>%s</key>\n' % (index))
                l.append(depth*'\t' + '<true/>\n')
            else:
                l.append(depth*'\t' + '<key>%s</key>\n' % (index))
                l.append(depth*'\t' + '<false/>\n')
        elif isinstance(item, int):
            l.append(depth*'\t' + '<key>%s</key>\n' % (index))
            l.append(depth*'\t' + '<integer>%s</integer>\n' % (item))
        else:
            if item == 'array':
                l.append(depth*'\t' + '<key>aliases</key>\n<array/>\n')
            else:
                l.append(depth*'\t' + '<key>%s</key>\n' % (index))
                l.append(depth*'\t' + '<string>%s</string>\n' % (item))
    return l


## Plist文件压缩处理
def minify_plist_file(dict_root, filepath):
    simp_text = "".join(dict_to_tree(dict_root, 2))
    if simp_text == '':
        return
    with open(filepath, 'w') as f:
        print 'simplify ' + os.path.basename(filepath) + ' ...'
        f.write('''<dict>\n''')
        f.write(simp_text)
        f.write('''</dict>''')


## Plist帧数解析处理
def parse_plist_file(frames, filepath):
    filepath = filepath.replace('\\', '/')
    file_basename = os.path.basename(filepath)
    file_dirname =  os.path.dirname(filepath).split('/')[-1]
    print 'parse ' + file_basename + ' ...'
    frame_format = ''
    
    ## 解析所有帧数
    frames_arr = []
    for index in frames.keys():
        pattern = re.compile(r"\d+")
        result  = pattern.findall(index)
        if len(result) > 0:
            frames_arr.append( int(result[-1]) )
    frame_format = index.split('_')[0]
    frames_arr.sort()

    ## 根据方向、动作分割帧数
    frames_info = {}
    pre_val = 0
    pre_idx = 0
    for value in frames_arr:
        index = str(value // 1000)
        if frames_info.get(index) is None:
            frames_info[index] = []
            pre_idx = 0
            pre_val = value
            
        if pre_val == 0 or value == pre_val:
            pre_val = value
            pre_idx = 0
            frames_info[index].append([])
        if value - pre_val > 1:
            pre_val = value
            pre_idx += 1
            frames_info[index].append([])
        pre_val = value
        frames_info[index][pre_idx].append(value)
    
    ## 转化为方向、动作（起始帧+帧数）
    new_frames_info = {}
    for frameindex, frameinfo in frames_info.iteritems():
        new_frames_info[frameindex] = [] 
        for index, info in enumerate(frameinfo):
            new_frames_info[frameindex].append([info[0], len(info)])

    ## 转化为Lua表
    frames = {
        'frames': new_frames_info,
        'texture': filepath.replace('../res/', '').replace('\\', '/'),
        'format': frame_format + '_%04d.png'
    }
    lua_name = os.path.splitext(file_basename)[0]
    lua_dir = ANIMATION_CONSTANTS['EDITOR_LUA_LOCATE'] + file_dirname
    if not os.path.exists(lua_dir):
        os.makedirs(lua_dir, True)
    write_dict_lua(frames, lua_name, lua_dir)

## 获得目录数量
def get_dir_num(path):
    dirnum = 0
    filenum = 0

    try:
        for lists in os.listdir(path):
            sub_path = os.path.join(path, lists)
            if os.path.isfile(sub_path):
                filenum = filenum + 1
            elif os.path.isdir(sub_path):
                dirnum = dirnum + 1
    except:
        pass

    return dirnum, filenum


## 遍历Plist文件
def walk_plist_files():
    if os.path.exists(ANIMATION_CONSTANTS['EDITOR_LUA_LOCATE']):
        shutil.rmtree(ANIMATION_CONSTANTS['EDITOR_LUA_LOCATE'])

    lua_files = {}
    plist_dirs = []
    for root, dirs, files in os.walk(ANIMATION_CONSTANTS['WALK_TARGET_DIR']):
        for dirpath in dirs:
            realpath = os.path.join(root, dirpath)
            if get_dir_num(realpath)[0] == 0:
                plist_dirs.append([dirpath, realpath])
    
    for dirinfo in plist_dirs:
        index = dirinfo[0]
        target_path = dirinfo[1]
        print('walk to : ' + index)

        lua_files[index] = []
        for root, dirs, files in os.walk(target_path):
            for filename in files:
                if filename.endswith('.plist'):
                    file_path = os.path.join(root, filename)
                    file_tree = ET.fromstring(open(file_path, 'r').read())
                    tree_root = file_tree[0]
                    dict_root = tree_to_dict(tree_root)
                    minify_plist_file(dict_root, file_path)
                    dict_root = tree_to_dict(file_tree)
                    frames = dict_root.get('frames')
                    if frames is not None:
                        parse_plist_file(frames, file_path)
                        lua_files[index].append(filename.split('.')[0])
                if filename.endswith('.png'):
                    file_path = os.path.join(root, filename)
                    lua_files[index].append(filename.split('.')[0])

    write_python_to_lua(lua_files, '_M', ANIMATION_CONSTANTS['EDITOR_LOAD_ITEMS'])

    print('All Done!')


## Python转Lua
def write_python_to_lua(dict_temp, lua_tablename, lua_filepath):
    json_str = json.dumps(dict_temp)
    lua_str  = str_to_lua_table(json_str)
    with open(lua_filepath, 'w') as f:
        f.write('local ' + lua_tablename + ' = ' + lua_str)
        f.write('\nreturn ' + lua_tablename)


if __name__ == "__main__":
    walk_plist_files()

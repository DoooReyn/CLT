#!/usr/bin/python
# encoding=utf-8

##################################################################
## Descrpition :
##   md5变更工具
## Author : Reyn
## Date : 2018/10/01
##################################################################

import json
import md5
import os
import sys

def getFileInfo(file):
    u'''获取文件信息'''

    with open(file, 'rb') as f:
        md = md5.new(f.read()).hexdigest()
        size = os.path.getsize(file)
        return {'md5' : md, 'size' : size}
    return None

class AssetsMd5Diff():
    u'''资源MD5比较工具'''

    def __init__(self):
        self.ignore_file       = './ignore.ini'
        self.version_file      = './version.manifest'
        self.project_file      = './project.manifest'
        self.src_dir           = './src'
        self.res_dir           = './res'
        self.ignore_json_dict  = {}      ##忽略的文件、目录字典
        self.old_version       = 0       ##旧版本号
        self.new_version       = 0       ##新版本号
        self.old_assets_dict   = {}      ##旧资源字典
        self.new_assets_dict   = {}      ##新资源字典
        self.is_assets_changed = False   ##资源是否变动

    def readVersion(self):
        u'''从版本文件读取版本号'''

        try:
            with open(self.version_file, 'r') as file:
                version_json_dict = json.load(file)
                self.old_version = version_json_dict['version']
        except:
            # print(u'读取版本文件 version.manifest 失败')
            print('read version file failed.')
            sys.exit(0)

    def readProject(self):
        u'''读取工程文件'''
        try:
            with open(self.project_file, 'r') as file:
                project_json_dict = json.load(file, encoding='utf-8')
                self.old_assets_dict = project_json_dict['assets']
        except:
            # print(u'读取工程文件 project.manifest 失败')
            print('read project file failed.')
            sys.exit(0)

    def writeVersion(self):
        u'''将新版本号写入版本文件'''

        try:
            with open(self.version_file, 'w') as file:
                self.new_version = self.old_version + 1
                str_json = {'version' : self.new_version}
                new_version_json = json.dumps(str_json, ensure_ascii=False, indent=4)
                file.write(new_version_json)
                # print(u'旧版本号: ' + str(self.old_version))
                # print(u'新版本号: ' + str(self.new_version))
                # print(u'完成！')
                print('old version : ' + str(self.old_version))
                print('new version : ' + str(self.new_version))
                print('Done!')
        except:
            # print(u'写入版本文件version.manifest失败')
            print('write version file failed.')
            sys.exit(0)

    def writeProject(self):
        u'''写入工程文件'''

        try:
            with open(self.project_file, 'w') as file:
                str_json = {'version' : self.new_version, 'assets' : self.new_assets_dict}
                project_json = json.dumps(str_json, sort_keys=True, ensure_ascii=False, indent=4)
                file.write(project_json)
        except:
            # print(u'写入工程文件project.manifest失败')
            print('write project file failed.')
            sys.exit(0)

    def readIgnore(self):
        u'''读取忽略文件'''
        try:
            with open(self.ignore_file, 'r') as file:
                self.ignore_json_dict = json.load(file, encoding='utf-8')
                print('ignore file list:')
                # print(u'忽略文件列表:')
                for file in self.ignore_json_dict.get('files'):
                    print '  ' + file
                # print(u'忽略目录列表:')
                print('ignore dir list:')
                for dirf in self.ignore_json_dict.get('dirs'):
                    print '  ' + dirf
        except:
            # print(u'读取忽略文件失败')
            print('read ignore file failed.')
            sys.exit(0)

    def readDirs(self, dirpath):
        u'''读取MD5值并记录到新的字典'''

        for root, _, files in os.walk(dirpath):
            for filename in files:
                filepath = os.path.join(root, filename)
                if filename == '.DS_Store':
                    os.remove(filepath)
                else:
                    is_in_root = True
                    for dirf in self.ignore_json_dict['dirs']:
                        if dirf in root:
                            is_in_root = False
                            break
                    if is_in_root:
                        fileinfo = getFileInfo(filepath)
                        if fileinfo is not None:
                            new_filename = filepath[2:].replace('\\', '/')
                            save_filename = filepath[6:].replace('\\', '/')
                            if new_filename not in self.ignore_json_dict['files']:
                                self.new_assets_dict[save_filename] = fileinfo
    def newMd5(self):
        u'''生成新的MD5值'''

        self.readDirs(self.res_dir)
        self.readDirs(self.src_dir)

    def diffMd5(self):
        u'''比对新旧的MD5值'''

        add_list = [] ##新增列表
        del_list = [] ##删除列表
        mod_list = [] ##修改列表

        for key, value in self.new_assets_dict.items():
            cv = self.old_assets_dict.get(key)
            if cv is None:
                add_list.append(key)
            else:
                if cv['md5'] != value['md5']:
                    mod_list.append(key)

        for key, value in self.old_assets_dict.items():
            nv = self.new_assets_dict.get(key)
            if nv is None:
                del_list.append(key)

        # state = u'统计:'
        state = 'total:'
        if len(add_list) > 0:
            # state += u'\n  新增:'+str(len(add_list))
            state += u'\n  add:'+str(len(add_list))
            diff = [ self.diffKey(key, 'ADD') for key in add_list ]
            # print u'新增:\n' + ''.join( diff )
            print u'add:\n' + ''.join( diff )
            self.is_assets_changed = True

        if len(del_list) > 0:
            # state += u'\n  删除:'+str(len(del_list))
            state += u'\n  del:'+str(len(del_list))
            diff = [ self.diffKey(key, 'DEL') for key in del_list ]
            # print u'删除:\n' + ''.join( diff )
            print u'del:\n' + ''.join( diff )
            self.is_assets_changed = True

        if len(mod_list) > 0:
            # state += u'\n  修改:'+str(len(mod_list))
            state += u'\n  mod:'+str(len(mod_list))
            diff = [ self.diffKey(key, 'MOD') for key in mod_list ]
            # print u'修改:\n' + ''.join( diff )
            print u'mod:\n' + ''.join( diff )
            self.is_assets_changed = True

        if self.is_assets_changed:
            print(state)
            # if raw_input('请确认后决定是否采用新的变化 (y/n)\n') == 'y':
            if raw_input('take effect (y/n)\n') == 'y':
                # print(u'正在为您写入...')
                print(u'writing...')
                self.writeVersion()
                self.writeProject()
            else:
                # print(u'您选择了什么都不做')
                print('do nothing.')
                sys.exit(0)
        else:
            # state += u'没有变化，无需更改'
            state += u'nothing changed.'
            print(state)

    def diffKey(self, key, mode='ADD'):
        u'''比较资源key值'''

        if mode == 'ADD':
            return '  ' + key + '\n    md5: ' + self.new_assets_dict.get(key)['md5'] + '\n'
        elif mode == 'DEL':
            return '  ' + key + '\n    md5: ' + self.old_assets_dict.get(key)['md5'] + '\n'
        elif mode == 'MOD':
            cv = self.old_assets_dict.get(key)['md5']
            nv = self.new_assets_dict.get(key)['md5']
            return '  ' + key + '\n     md5: ' + cv + ' => ' + nv + '\n'
        return ''

    def start(self):
        self.readIgnore()
        self.readVersion()
        self.readProject()
        self.newMd5()
        self.diffMd5()

if __name__ == '__main__':
    AssetsMd5Diff().start()

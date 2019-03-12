#!/usr/bin/env python
# -*- coding: utf-8 -*-.
import os,os.path,re,time,string
import shutil
def copyFiles(sourceDir, targetDir):
    for f in os.listdir(sourceDir):
        sourceF = os.path.join(sourceDir, f)
        targetF = os.path.join(targetDir, f)
        if os.path.isfile(sourceF):
            if not os.path.exists(targetDir):
                os.makedirs(targetDir)
            open(targetF, "wb").write(open(sourceF, "rb").read())
        if os.path.isdir(sourceF):
            copyFiles(sourceF, targetF)

def removeDir(rootdir):
    filelist=os.listdir(rootdir)
    for f in filelist:
        filepath = os.path.join( rootdir, f )
        if os.path.isfile(filepath):
            os.remove(filepath)
        elif os.path.isdir(filepath):
            shutil.rmtree(filepath,True)

def getDirFiles(targDir):
    for root, dirs, files in os.walk(targDir):  
        for file in files:  
            path = os.path.join(root, file)
            if (not re.match(r".*(\.svn|\.project|html\.\d+|Thumbs\.db).*", path)):# and os.path.getmtime(file)>t :  
                filelist.append(path)

def resJsonFileDeal(dirName):
    dirList = [os.path.join(resPath , dirName , f) for f in os.listdir(os.path.join(curPath , dirName)) if os.path.isdir(os.path.join(curPath , dirName , f))]
    for _dir in dirList:
        copyFiles(_dir , os.path.join(curPath , dirName))
        removeDir(_dir)
        os.rmdir(_dir)

def getPreTime():
    if os.path.exists(os.path.join(curPath , 'runappCfg')):
        f = open(os.path.join(curPath , 'runappCfg'), 'r')
        all_the_text = f.read()
        
        if all_the_text == '':
            return 0
        else:
            return string.atof(all_the_text)
    else:
        return 0

curPath = os.path.abspath(".")
resPathArr = []#["Sound","csb","Proto"]
srcPath = os.path.join(curPath , 'src')
preTime = getPreTime()
filelist=[]

for resPath in resPathArr:
    command = 'adb push  %s /mnt/sdcard/lyzz_script/res/%s' %(os.path.join(curPath,"res",resPath),resPath)
    os.system(command)

for root, dirs, files in os.walk(srcPath):
    for file in files:
        path= os.path.join(root, file)
        if (not re.match(r".*(\.svn|\.project|html\.\d+|Thumbs\.db).*", path)):# and os.path.getmtime(file)>t :  
            filelist.append(path)

# print u'上次拷贝时间:' + time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(preTime))
# if preTime == 0:
os.system('adb shell mkdir /mnt/sdcard/lyzz_script/')
os.system('adb push  %s /mnt/sdcard/lyzz_script/src' % srcPath)
# else:
#     for i in filelist:
#         insertFlag = False
#         temp = '';
#         if os.path.getmtime(i) > preTime:
#             print u'拷贝修改文件:%s' % i #, preTime.strftime('%Y-%m-%d %H:%M:%S',preTime.gmtime(os.path.getmtime(i)))
#             if os.path.splitext(i)[1] == '.lua':
#                 for p in i.split('\\'):
#                     if p == 'src':
#                         insertFlag = True
#                     if insertFlag:
#                         temp = temp + '/' + p
#                 os.system('adb push  %s /mnt/sdcard/lyzz_script%s' % (i , temp))
#             else:
#                 for p in i.split('\\'):
#                     if p == 'res':
#                         insertFlag = True
#                     if insertFlag:
#                         temp = temp + '/' + p
#                 os.system('adb push  %s /mnt/sdcard/lyzz_script%s' % (i , temp))



# f = open(os.path.join(curPath , 'runappCfg'), 'w')
# f.write('%f' %time.time())
# f.close()

os.system('adb shell am force-stop com.zqgame.lyzz')
os.system('adb shell am start -n com.zqgame.lyzz/com.zqgame.zscq.AppActivity')
os.system('pause')

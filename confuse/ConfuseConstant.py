#!/usr/bin/python
# -*- coding: utf-8 -*-

CONFUSE_CONSTANT = {
    'MAX_RUBBISH_SCALE'       : 10, #生成垃圾文件的最大倍数
    'MAX_RUBBISH_SENTENSES'   : 20, #垃圾文件随机内容最大句数
    'RUBBISH_FILE_EXTENSIONS' : ['.cfg', '.txt', '.adt', '.csv', '.dat', '.log', '.tbl', '.table'], #垃圾文件的扩展名
    'CONFUSED_LOCATED_PATH'   : './confuse_work_dir/', #混淆输出所在路径
    'ORIGINAL_RESOURCE_PATH'  : '../../res/', #需要混淆的资源所在路径
    'CONFUSED_RESOURCE_PATH'  : './confuse_work_dir/res/', #混淆生成的资源所在路径
    'ORIGINAL_SOURCE_PATH'    : '../../src/', #需要混淆的代码所在路径
    'SOURCE_ENCRYPT_KEY'      : '19850321_HuCanHua', # 代码加密key
    'SOURCE_ENCRYPT_SIGN'     : 'zqgame_tdht_09', # 代码加密sign
    'CONFUSED_SOURCE_PATH'    : './confuse_work_dir/src/', #混淆生成的代码所在路径
    'RUBBISH_PNG_PREFIX'      : 'rub', ##垃圾图片标记
}

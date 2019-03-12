#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import xml.etree.ElementTree as ET

WALK_DIR = '../res'

## XML转化为Dict
def tree_to_dict(tree):
    d = {}
    for index, item in enumerate(tree):
        if item.tag == 'key':
            tag = tree[index+1].tag
            if tag == 'string':
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


## Plist文件处理
def minify_plist_file(filepath):
    tree_root = ET.fromstring(open(filepath, 'r').read())[0]
    dict_root = tree_to_dict(tree_root)
    simp_text = "".join(dict_to_tree(dict_root, 2))
    if simp_text == '':
        return
    with open(filepath, 'w') as f:
        print 'simplify ' + os.path.basename(filepath) + ' ...'
        f.write('''<dict>\n''')
        f.write(simp_text)
        f.write('''</dict>''')


## 遍历Plist文件
def walk_plist_files():
    for root, dirs, files in os.walk(WALK_DIR):
        for filename in files:
            if filename.endswith('.plist'):
                minify_plist_file(os.path.join(root, filename))
    print('done!')


if __name__ == "__main__":
    walk_plist_files()

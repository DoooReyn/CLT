#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import re
import json

class GenerateLuaApi():

    def __init__(self):
        self.src_dirs = [
            '../frameworks/cocos2d-x/cocos/scripting/lua-bindings/auto/',
            # '../frameworks/cocos2d-x/cocos/scripting/lua-bindings/manual/'
        ]
        self.lua_keywords = [
            'lua_pushstring',
            'tolua_usertype',
            'tolua_function',
        ]
        self.extract_file = './extract_lua_api.txt'
        self.parsed_file = './parsed_lua_api.txt'
        self.extract_section = {}

    def parse(self):
        if self.extract_section:
            json_text = json.dumps(self.extract_section, ensure_ascii=False, indent=4)
            try:
                os.makedirs('./lua_api/')
            except:
                pass
            with open('./lua_api/api.json', 'w') as f:
                f.write(json_text)

            values = {}
            for key, val in self.extract_section.items():
                for v in key.split('.'):
                    values[v] = True
                for v in val:
                    values[v] = True
            with open('./lua_api/api_binding.lua', 'w') as f:
                f.write('return {\n')
                f.writelines(['\t'+value+' = true,\n' for value in values])
                f.write('}\n')

    def contract(self, filepath):
        extract_lines = []
        with open(filepath, 'r') as f:
            for line in f.readlines():
                line = line.strip()
                for keyword in self.lua_keywords:
                    if line.find(keyword) >= 0:
                        extract_lines.append(line+'\n')
        if len(extract_lines) > 0:
            pattern = re.compile('"(.*)"')
            prefix = None
            for exline in extract_lines:
                if exline.find('tolua_usertype') >= 0:
                    prefix_tab = pattern.findall(exline)
                    if len(prefix_tab) > 0:
                        prefix = prefix_tab[0]
                        self.extract_section[prefix] = []
                        print('prefix : ' + prefix)
                if exline.find('lua_pushstring') >= 0:
                    prefix_tab = pattern.findall(exline)
                    if len(prefix_tab) > 0:
                        if prefix_tab[0].find('.') >= 0:
                            prefix = prefix_tab[0]
                            self.extract_section[prefix] = []

                if exline.find('tolua_function') >= 0:
                    api_tab = pattern.findall(exline)
                    if len(api_tab) > 0 and prefix is not None:
                        api = api_tab[0]
                        self.extract_section[prefix].append(api)


    def walkdir(self, onedir):
        for root, _, files in os.walk(onedir):
            for filename in files:
                if filename.endswith('.cpp'):
                    path = os.path.join(root, filename)
                    self.contract(path)

    def generate(self):
        for onedir in self.src_dirs:
            self.walkdir(onedir)
        self.parse()

if __name__ == "__main__":
    GenerateLuaApi().generate()
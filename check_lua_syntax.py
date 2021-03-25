# encoding=utf8

import os
import re
import sys


class LuaSyntaxChecker:
    def __init__(self, root):
        self.__lua_check = None
        self.__root = None
        self.__errors = []
        self.check_root(root)
        self.search_lua_checker()
        self.run_check(self.__root)
        self.statistic()

    def statistic(self):
        if len(self.__errors) > 0:
            print("All done! Errors list below:")
        for i, v in enumerate(self.__errors):
            print(v)
        else:
            print("All done! Everything is ok!")

    def check_root(self, root):
        if os.path.exists(root):
            self.__root = root
        else:
            print("invalid directory: %s" % root)
            sys.exit(-1)

    def search_lua_checker(self):
        paths = os.environ.get("path").split(";")
        for p in paths:
            lp = os.path.join(p, "luacheck.exe")
            if os.path.exists(lp):
                self.__lua_check = lp
                break
        if self.__lua_check is None:
            print("luacheck not found.")
            sys.exit(-1)
            return
        print("luacheck found at: %s" % self.__lua_check)

    def run_check(self, where):
        if os.path.isfile(where):
            self.check_lua_syntax(where)
            return
        for root, dirs, files in os.walk(where):
            for file in files:
                ext = os.path.splitext(file)[-1]
                if ext == ".lua":
                    full = os.path.join(root, file)
                    self.check_lua_syntax(full)

    def check_lua_syntax(self, path):
        cmd = self.__lua_check + " " + path
        output = os.popen(cmd)
        output = output.read()
        info = output.split("\n")[-2]
        pattern = r"Total: (\d+) warnings / (\d+) error in 1 file"
        raises = re.match(pattern, info, re.I)
        if raises is not None:
            raises = raises.groups(0)
            if raises and len(raises) == 2:
                errors = raises[1]
                if errors > 0:
                    self.__errors.append("%s error: %s, details:\n%s" %
                                         (path, errors, output))
                    print("error: [%s] (%s)" % (
                        path, errors))
                    return
        print("ok: [%s]" % path)


if __name__ == '__main__':
    def help():
        print("[Help] To check Lua syntax, a Lua file path or directory is needed.")

    if len(sys.argv) == 2:
        root = sys.argv[1]
        if root == "-h":
            help()
        else:
            LuaSyntaxChecker(root)
    else:
        help()

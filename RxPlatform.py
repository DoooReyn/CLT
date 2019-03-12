# encoding=utf-8

import os
import platform

class RxPlatform():
    def __init__(self):
        self.platform_os = platform.system()

    def isWindows(self):
        return 'Windows' in self.platform_os

    def isMacOs(self):
        return 'Darwin' in self.platform_os

    def isLinux(self):
        return 'Linux' in self.platform_os

    def getOsSep(self):
        return os.path.sep


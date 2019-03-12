@echo off
rem input param

set resPath=%1
set plistPath=%2N{n}.plist
set pvrPath=%2N{n}.pvr.ccz

rem tp path
set tool="TexturePacker.exe"

set param=--format cocos2d
set param=%param% --replace a=%3
set param=%param% --data %plistPath%
set param=%param% --texture-format pvr2ccz
set param=%param% --sheet %pvrPath%
set param=%param% --premultiply-alpha
set param=%param% --opt RGBA4444 
set param=%param% --max-size 4096
set param=%param% --size-constraints AnySize
set param=%param% --scale 1
set param=%param% --algorithm MaxRects
set param=%param% --shape-padding 2
set param=%param% --border-padding 2
set param=%param% --enable-rotation
set param=%param% --trim-mode Trim
set param=%param% --multipack
%tool% %param% %resPath%
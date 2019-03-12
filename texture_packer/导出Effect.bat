@echo off
rem call param1:资源目录 param2:输出路径
rem ---- Effect ----
set outDir=..\res\Textures\Effect\e
for /d %%i in (Effect\*) do (          
	call TexturePackerForEffect.bat %%i %outDir%%%~ni e%%~ni_
)

pause
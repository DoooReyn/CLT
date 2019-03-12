@echo off
for /r %%i in (*.proto) do (          
	rem echo %%~ni
	protoc --descriptor_set_out ./res/Proto/%%~ni.pb %%~ni.proto
)

pause
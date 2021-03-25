Write-Output "���ܣ����Quick���뻷��"

$user = [Environment]::GetEnvironmentVariable("COCOS_CONSOLE_ROOT", "User")
$sys = [Environment]::GetEnvironmentVariable("COCOS_CONSOLE_ROOT", "Machine")
$ok = $sys -or $user
if ($user) {
    $path = $user
}
if ($sys) {
    $path = $sys
}
if ($sys -or $user) {
    Write-Output ("COCOS_CONSOLE_ROOT => " + $path)
    $path1 = Write-Output ($path + "/../plugins/plugin_luacompile/bin2030")
    $path2 = Write-Output ($path + "/../plugins/plugin_luacompile/bin2103")
    $ok1 = Test-Path $path1
    $ok2 = Test-Path $path2
    if($ok1 -and $ok2) {
        Write-Output "Quick��������"
    }
} else {
    Write-Output "�������� COCOS_CONSOLE_ROOT"
}

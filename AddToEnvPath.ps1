Write-Output "功能：添加路径到PATH环境变量"
Write-Output "请按照指示操作"

$level = Read-Host "请选择操作级别：（0：用户，1-系统）"
$target = "User"
if($level -eq "1")  {
    $target = "Machine"
}

$old = [Environment]::GetEnvironmentVariable("Path", $target)
$old_arr = $old.split(";")
$add = Read-Host "请输入需要添加的路径"

[bool] $exist = $false
Foreach($var in $old_arr) {
    if ($var -eq $add) {
        $exist = $true
        break
    }
}

if ($exist) {
    Write-Output "路径已存在，已终止下一步操作"
} else {
    $new = $old + ";" + $add
    Write-Output ""
    Write-Output "新的环境变量PATH如下："
    Write-Output $new.split(";")
    Write-Output ""
    $ok = Read-Host "请确认无误后选择操作(0-取消, 1-确认)"
    if ($ok -eq "0") {
        Write-Output "您取消了操作"
    } else {
        [Environment]::SetEnvironmentVariable("Path", $new, $target)
        Write-Output "PATH已更新"
    }
}
pause
Write-Output "���ܣ����·����PATH��������"
Write-Output "�밴��ָʾ����"

$level = Read-Host "��ѡ��������𣺣�0���û���1-ϵͳ��"
$target = "User"
if($level -eq "1")  {
    $target = "Machine"
}

$old = [Environment]::GetEnvironmentVariable("Path", $target)
$old_arr = $old.split(";")
$add = Read-Host "��������Ҫ��ӵ�·��"

[bool] $exist = $false
Foreach($var in $old_arr) {
    if ($var -eq $add) {
        $exist = $true
        break
    }
}

if ($exist) {
    Write-Output "·���Ѵ��ڣ�����ֹ��һ������"
} else {
    $new = $old + ";" + $add
    Write-Output ""
    Write-Output "�µĻ�������PATH���£�"
    Write-Output $new.split(";")
    Write-Output ""
    $ok = Read-Host "��ȷ�������ѡ�����(0-ȡ��, 1-ȷ��)"
    if ($ok -eq "0") {
        Write-Output "��ȡ���˲���"
    } else {
        [Environment]::SetEnvironmentVariable("Path", $new, $target)
        Write-Output "PATH�Ѹ���"
    }
}
pause
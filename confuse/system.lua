local system = {}

system.os = io.popen("uname -s"):read("*l") or 'Windows'
system.isWindows = system.os == 'Windows'
system.isDarwin  = system.os == 'Darwin'
system.isLinux   = system.os == 'Linux'
system.separator = system.isWindows and '\\' or '/'

return system
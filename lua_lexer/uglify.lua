local RandomWord = require('RandomWord')
local FileSystem = require('lfs')

local function swap_key_val(tab)
	local t = {}
	for k, v in pairs(tab) do
		t[tostring(v)] = tostring(k)
	end
	return t
end

local function uglify(code)
    local keymap = {}
    local mapkey = {}
    local uglycode = string.gsub(code, "([%w_]+)", function(s)
        if tonumber(s) then
            return s
        end
        if not keymap[s] and not mapkey[s] then
            local key = RandomWord()
            if not mapkey[key] and not keymap[key] then
                mapkey[key] = s
                keymap[s] = key
            end
        end
        return keymap[s]
	end)
	return uglycode, swap_key_val(keymap)
end

local function getFileContent(filepath)
    local f = io.open(filepath, 'r')
    if f then
        return f:read('*a')
    end
    return nil
end

local function minify(code)
    local lines = {}
    for _, line in ipairs(string.split(code, '\n')) do
        line = string.gsub(line, '[^%s+]', function(s)
            return s
        end)
        
        line = string.gsub(line, '^ +', function(s)
            return ''
        end)

        local from = 0
        line = string.gsub(line, '%s+', function(s)
            from = from + 1
            if from == 1 then
                return s
            end
        	return ' '
        end)
        
        if not line.match(line, '^%s?%-%-') then
            local sub = string.find(line, '%-%-+')
            local str = line
            if sub and sub > 0 then
                str = string.sub(line, 1, sub-1)
            end
            if string.find(str, '[^%s]') then
                local sub = string.find(str, 'print')
                if sub == nil then
                    lines[#lines+1] = str
                end
            end
        end
    end
    return table.concat(lines, '\n')
end

local function restore(c, k) 
    local str = string.gsub(c, "([%w_]+)", function(s) 
        if k[s] then 
            return k[s] 
        end 
        return s
    end) 
    return str
end

function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

local function write_uglycode(filepath, code, map)
    local f = io.open(filepath, 'w')
    if f then
        f:write([==[local function restore(c, k) return string.gsub(c, "([%w_]+)", function(s) if k[s] then return k[s] end end) end]==])
        f:write("\n\nlocal tab = {\n")
        for k, v in pairs(map) do
            f:write( string.format('["%s"]="%s",\n', k, v) )
        end
        f:write("}\n\n")
        f:write("local code = restore([==[\n")
        f:write(code)
        f:write("]==], tab)\n\n")
        f:write("return loadstring(code)()\n")
        f:close()
    end
end

local function write_restore_code(filepath, code)
    local f = io.open(filepath, 'w')
    if not f then return end
    f:write(code)
    f:close()
end

function lfs.walk(rootPath, key)
    local dirs, files = {}, {}
    local isdir  = (key == 'directory' or key == nil)
    local isfile = (key == 'file' or key == nil)

    for entry in lfs.dir(rootPath) do
        if entry ~= '.' and entry ~= '..' then
            local path = rootPath .. '\\' .. entry
            local attr = lfs.attributes(path)
            if type(attr) == 'table' then
                if attr.mode == 'directory' then
                    local _attr = lfs.walk(path)
                    if isdir then
                        table.insert(dirs, path)
                        for _, _dir in ipairs(_attr.dirs) do
                            table.insert(dirs, _dir)
                        end
                    end
                    for _, _file in ipairs(_attr.files) do
                        table.insert(files, _file)
                    end
                elseif attr.mode == 'file' then
                    if isfile then
                        table.insert(files, path)
                    end
                end
            end
        end
    end
    return {dirs = dirs, files = files}
end

function lfs.join(p1, p2)
    return p1 .. '\\' .. p2
end

function lfs.walkdirs(rootPath, callfn)
    local attr = lfs.walk(rootPath, 'directory')
    for k, v in ipairs(attr.dirs) do
        callfn(k, v)
    end
end

function lfs.walkfiles(rootPath, callfn)
    local attr = lfs.walk(rootPath, 'file')
    for k, v in ipairs(attr.files) do
        callfn(k, v)
    end
end

local function write_one_file(filepath)
    local code = getFileContent(filepath)
    local code, map = uglify(minify(code))
    local rcode = restore(code, map)
    write_restore_code(filepath, rcode)
    -- write_uglycode(filepath, code, map)
end

local function write_files()
    lfs.walkfiles('../../src/game/control/', function(_, filepath)
        local find = string.find(filepath, '.lua')
        if find > 0 then
            local code = getFileContent(filepath)
            local code, map = uglify(minify(code))
            write_uglycode(filepath, code, map)
            print('writing '..filepath)
        end
    end)
end

-- write_files()
write_one_file('../../src/game/control/Player.lua')
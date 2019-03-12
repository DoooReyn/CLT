----------------------------------------------------------------------------------
-- TODO
-- 当前还是混淆的初级阶段，容易被还原出来或者猜测到混淆原理。对此，可增加如下几点优化：
--  1. 增加映射的复杂度，可做如下处理：
--     1) 多键值
--     2) 值映射为另一张表，剔除重复，原表映射为数值
--  2. 隐藏替换方法
----------------------------------------------------------------------------------

package.path = package.path .. ';../lua_api/?.lua;'
local lfs    = require 'lfs'
local lexer  = require 'lexer'
local rw     = require('RandomWord')

local function _dump(var, indent)
    local _t = {}
    indent = indent or 0
    if type(var) == 'table' then
        table.insert(_t, '<table> \n')
        indent = indent + 4
        for k, v in pairs(var) do
            local c = table.concat(_dump(v, indent), '')
            table.insert(_t, string.rep(' ', indent) .. string.format('[%s] => %s\t`%s`,\n', k, c, tostring(v)))
        end
        table.insert(_t, string.rep(' ', indent-4))
    else
        table.insert(_t, '<' .. type(var) .. '>')
    end
    return _t
end

local function dump(var)
    print( table.concat(_dump(var), '') )
end

local function swap_key_val(tab)
	local t = {}
	for k, v in pairs(tab) do
		t[tostring(v)] = tostring(k)
	end
	return t
end

function lfs.walk(rootPath, key)
    local dirs, files = {}, {}
    local isdir  = (key == 'directory' or key == nil)
    local isfile = (key == 'file' or key == nil)

    for entry in lfs.dir(rootPath) do
        if entry ~= '.' and entry ~= '..' then
            local path = rootPath .. '/' .. entry
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

local file = {}
function file.read(filepath)
    local content = nil
    local f = io.open(filepath, 'r')
    if f then
        content = f:read("*a")
        f:close()
    end
    return content
end

local function extract(lines, key)
    local words = {}
    if type(lines) == 'table' then
        for _, line in ipairs(lines) do
            for _, word in ipairs(line) do
                if word.type == key then
                    words[word.data] = true
                end
            end
        end
    end
    return words
end

function lexer.parse_file(filepath)
    local text = file.read(filepath)
    local lines = lexer.parse(text)
    local words = extract(lines, 'ident')
    return words
end

local function parse_cclibs()
    local idents = {}
    lfs.walkfiles('../../src/cclibs/', function(line, filepath)
        local words = lexer.parse_file(filepath)
        for k in pairs(words) do
            idents[k] = true
        end
    end)
    return idents
end

local function write_cclibs()
    local f = io.open('../lua_api/api_libs.lua', 'w')
    if not f then
        print('api_libs.lua 文件打开失败')
        return
    end
    f:write('return {\n')
    local idents = parse_cclibs()
    for k in pairs(idents) do
        f:write('\t' .. k .. ' = true,\n')
    end
    f:write('}\n')
    f:close()

    local f = io.open('../lua_api/api.lua', 'w')
    if not f then
        print('api.lua 文件打开失败')
        return
    end
    f:write('return {\n')
    local binding = require('api_binding')
    for k in pairs(binding) do
        f:write('\t' .. k .. ' = true,\n')
    end
    local game = require('api_game')
    for k in pairs(game) do
        f:write('\t' .. k .. ' = true,\n')
    end
    local libs = require('api_libs')
    for k in pairs(libs) do
        f:write('\t' .. k .. ' = true,\n')
    end
    f:write('}\n')
    f:close()
end

local function lexer_parse(filepath)
    local filter_words = require('api')
    local parsed_words = lexer.parse_file(filepath)
    local result_words = {}
    for k in pairs(parsed_words) do
        if not filter_words[k] then
            result_words[k] = true
        end
    end
    dump(result_words)
end

local function RandomWord()
    local _M = {words = {}}
    function _M:random()
        while true do
            local word = rw()
            if not self.words[word] then
                self.words[word] = true
                return word
            end
        end
        return nil
    end
    return _M
end

local function restore(g, c, k)
    local str = string.gsub(c, g.."([0-9]+)", function(s)
        return k[tonumber(s)]
    end)
    return str
end

local RESTORE_STRING = [=[
local function %s(g, c, k) local str = string.gsub(c, g.."([0-9]+)", function(s) return k[tonumber(s)] end) return str end]=]

local ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
local RW = RandomWord()
local function uglify(parsedTab)
    local key = RW:random()
    local newTab = {}
    local idents = {}
    for lineId, lineTab in ipairs(parsedTab) do
        local lineArr = {}
        for i, v in ipairs(lineTab) do
            local word = v.data
            if v.type == 'comment' then
            elseif v.type == 'whitespace' then
                table.insert(lineArr, ' ')
            elseif v.type == 'ident' then
                if string.len(word) >= 3 and string.match(v.data, '^[a-zA-Z_]') then
                    word = key .. (#idents+1)
                    idents[#idents+1] = v.data
                end
                table.insert(lineArr, word)
            else
                table.insert(lineArr, word)
            end
        end
        local line = table.concat(lineArr, '')
        if string.find(line, '[^%s+]') then
            line = string.gsub(line, '  ', function()
                return ' '
            end)
            table.insert(newTab, line .. '\n')
        end
    end
    return key, table.concat(newTab, ''), idents
end

local function squish(parsedTab)
    local newTab = {}
    for lineId, lineTab in ipairs(parsedTab) do
        local lineArr = {}
        for i, v in ipairs(lineTab) do
            if v.type == 'comment' then
            elseif v.type == 'whitespace' then
                table.insert(lineArr, ' ')
            else
                table.insert(lineArr, v.data)
            end
        end
        local line = table.concat(lineArr, '')
        if string.find(line, '[^%s+]') then
            line = string.gsub(line, '  ', function()
                return ' '
            end)
            table.insert(newTab, line .. '\n')
        end
    end
    -- dump(idents)
    return table.concat(newTab, '')
end

local function uglifyWithFile(filepath)
    local content = file.read(filepath)
    local key, code, map = uglify(lexer.parse(content))
    local f = io.open(filepath, 'w')
    if not f then return end
    local fun_key = RW:random()
    local tab_key = RW:random()
    local code_key = RW:random()
    f:write(string.format(RESTORE_STRING, fun_key))
    f:write(string.format("\n\nlocal %s = {", tab_key))
    local i = 0
    for k, v in pairs(map) do
        f:write( string.format('"%s",', v) )
        i = i + 1
        if i % 20 == 0 then
            f:write('\n')
        end
    end
    f:write("}\n\n")
    f:write(string.format("local %s = %s('%s', [==[\n", code_key, fun_key, key))
    f:write(code)
    f:write(string.format("]==], %s)\n\n", tab_key))
    f:write(string.format("return loadstring(%s)()\n", code_key))
    f:close()
    print('confusing '..filepath)
end

local function squishWithFile(filepath)
    local content = file.read(filepath)
    local code = squish(lexer.parse(content))
    local f = io.open(filepath, 'w')
    if not f then return end
    f:write(code)
    f:close()
    print('writing '..filepath)
end

-----------------------------------------test-----------------------------------------
local function confuse_files()
    lfs.walkfiles('./confused_src_path/src/game/const', function(_, filepath)
        local find = string.find(filepath, '.lua')
        if find and find > 0 then
            uglifyWithFile(filepath)
        end
    end)
end

confuse_files()

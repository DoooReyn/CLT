----------------------------------------------------------------------------------
-- TODO
-- 当前还是混淆的初级阶段，容易被还原出来或者猜测到混淆原理。对此，可增加如下几点优化：
--  1. 增加映射的复杂度，可做如下处理：
--     1) 多键值
--     2) 值映射为另一张表，剔除重复，原表映射为数值
--  2. 隐藏替换方法
----------------------------------------------------------------------------------

------------------------------ 模块引用 ------------------------------
package.path = package.path .. ';../lua_api/?.lua;'
local lfs    = require 'lfs'
local lexer  = require 'lexer'
local rw     = require('RandomWord')
local system = require('system')

------------------------------ 数据打印 ------------------------------
--组织可打印的数据结构
local function _dump(var, indent)
    local _t = {}
    indent = indent or 0
    if type(var) == 'table' then
        table.insert(_t, '<table> \n')
        indent = indent + 4
        for k, v in pairs(var) do
            local c = table.concat(_dump(v, indent), '')
            table.insert(_t, string.rep(' ', indent) .. string.format('[%s] => %s,\n', k, c))
        end
        table.insert(_t, string.rep(' ', indent-4))
    else
        table.insert(_t, '<' .. type(var) .. '> ')
        table.insert(_t, '`' .. tostring(var) .. '`')
    end
    return _t
end

--打印数据结构
local function dump(var)
    print( table.concat(_dump(var), '') )
end

------------------------------ 文件操作 ------------------------------

--遍历文件目录
function lfs.walk(rootPath, key)
    local dirs, files = {}, {}
    local isdir  = (key == 'directory' or key == nil)
    local isfile = (key == 'file' or key == nil)

    for entry in lfs.dir(rootPath) do
        if entry ~= '.' and entry ~= '..' then
            local path = rootPath .. system.separator .. entry
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

--文件路径拼接
function lfs.join(p1, p2)
    return p1 .. system.separator .. p2
end

--遍历文件目录（仅所有目录）
function lfs.walkdirs(rootPath, callfn)
    local attr = lfs.walk(rootPath, 'directory')
    for k, v in ipairs(attr.dirs) do
        callfn(k, v)
    end
end

--遍历文件目录（仅所有文件）
function lfs.walkfiles(rootPath, callfn)
    local attr = lfs.walk(rootPath, 'file')
    for k, v in ipairs(attr.files) do
        callfn(k, v)
    end
end

--读文件
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

------------------------------ 混淆准备 ------------------------------

--恢复
local function restore(g, c, k)
    local str = string.gsub(c, g.."([0-9]+)", function(s)
        return k[tonumber(s)]
    end)
    return str
end

--恢复字符串（lua用）
local RESTORE_STRING = [=[
local function %s(g, c, k) local str = string.gsub(c, g.."([0-9]+)", function(s) return k[tonumber(s)] end) return str end]=]

--随机单词
local function random_word()
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

------------------------------ 混淆实现 ------------------------------
local CONFUSE_SOURCE_PATH = './confuse_work_dir/src/game/'

local Confuse = {}

function Confuse:new()
    --混淆限定目录
    self.confuse_dir = CONFUSE_SOURCE_PATH
    --混淆单词生成器
    self.RW = random_word()

    return self
end

--丑化数据
function Confuse:uglify(parsedTab)
    local key = self.RW:random()
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

--压缩数据
function Confuse:squish(parsedTab)
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

--丑化文件
function Confuse:uglifyWithFile(filepath)
    local content = file.read(filepath)
    local key, code, map = self:uglify(lexer.parse(content))
    local f = io.open(filepath, 'w')
    if not f then return end
    local fun_key  = self.RW:random()
    local tab_key  = self.RW:random()
    local code_key = self.RW:random()
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

--压缩文件
function Confuse:squishWithFile(filepath)
    local content = file.read(filepath)
    local code = self:squish(lexer.parse(content))
    local f = io.open(filepath, 'w')
    if not f then return end
    f:write(code)
    f:close()
    print('writing '..filepath)
end

--混淆所有文件
function Confuse:confuse_files()
    lfs.walkfiles(self.confuse_dir, function(_, filepath)
        local find = string.find(filepath, '.lua')
        if find and find > 0 then
            self:uglifyWithFile(filepath)
        end
    end)
    print('Lua Files Confused!!!')
end

------------------------------ 开始混淆 ------------------------------

if arg and #arg > 0 and arg[1] == '--start-confuse' then
    Confuse:new():confuse_files()
end

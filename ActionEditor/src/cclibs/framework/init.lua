--[[

Copyright (c) 2011-2015 chukong-incc.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

if type(DEBUG) ~= "number" then DEBUG = 0 end

-- load framework
printInfo("")
printInfo("# DEBUG                        = " .. DEBUG)
printInfo("#")

device     = require("cclibs.framework.device")
display    = require("cclibs.framework.display")
audio      = require("cclibs.framework.audio")
transition = require("cclibs.framework.transition")

require("cclibs.framework.extends.NodeEx")
require("cclibs.framework.extends.SpriteEx")
require("cclibs.framework.extends.LayerEx")
require("cclibs.framework.extends.MenuEx")

if ccui then
require("cclibs.framework.extends.UIWidget")
require("cclibs.framework.extends.UICheckBox")
require("cclibs.framework.extends.UIEditBox")
require("cclibs.framework.extends.UIListView")
require("cclibs.framework.extends.UIPageView")
require("cclibs.framework.extends.UIScrollView")
require("cclibs.framework.extends.UISlider")
require("cclibs.framework.extends.UITextField")
end

require("cclibs.framework.package_support")

-- register the build-in packages
cc.register("event", require("cclibs.framework.components.event"))

-- export global variable
local __g = _G
cc.exports = {}
setmetatable(cc.exports, {
    __newindex = function(_, name, value)
        rawset(__g, name, value)
    end,

    __index = function(_, name)
        return rawget(__g, name)
    end
})

-- disable create unexpected global variable
function cc.disable_global()
    setmetatable(__g, {
        __newindex = function(_, name, value)
            error(string.format("USE \" cc.exports.%s = value \" INSTEAD OF SET GLOBAL VARIABLE", name), 0)
        end
    })
end

--enable create unexpected global variable
function cc.enable_global()
    setmetatable(_G, {__index = _G})
end

if CC_DISABLE_GLOBAL then
    cc.disable_global()
end

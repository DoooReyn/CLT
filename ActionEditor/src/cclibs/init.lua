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

require "cclibs.cocos2d.Cocos2d"
require "cclibs.cocos2d.Cocos2dConstants"
require "cclibs.cocos2d.functions"

__G__TRACKBACK__ = function(msg)
    local msg = debug.traceback(msg, 3)
    print(msg)
    return msg
end

-- opengl
require "cclibs.cocos2d.Opengl"
require "cclibs.cocos2d.OpenglConstants"
-- audio
require "cclibs.cocosdenshion.AudioEngine"
-- cocosstudio
if nil ~= ccs then
    require "cclibs.cocostudio.CocoStudio"
end
-- ui
if nil ~= ccui then
    require "cclibs.ui.GuiConstants"
    require "cclibs.ui.experimentalUIConstants"
end

-- extensions
require "cclibs.extension.ExtensionConstants"
-- network
require "cclibs.network.NetworkConstants"
-- Spine
if nil ~= sp then
    require "cclibs.spine.SpineConstants"
end

require "cclibs.cocos2d.deprecated"
require "cclibs.cocos2d.DrawPrimitives"

-- Lua extensions
require "cclibs.cocos2d.bitExtend"

-- CCLuaEngine
require "cclibs.cocos2d.DeprecatedCocos2dClass"
require "cclibs.cocos2d.DeprecatedCocos2dEnum"
require "cclibs.cocos2d.DeprecatedCocos2dFunc"
require "cclibs.cocos2d.DeprecatedOpenglEnum"

-- register_cocostudio_module
if nil ~= ccs then
    require "cclibs.cocostudio.DeprecatedCocoStudioClass"
    require "cclibs.cocostudio.DeprecatedCocoStudioFunc"
end


-- register_cocosbuilder_module
require "cclibs.cocosbuilder.DeprecatedCocosBuilderClass"

-- register_cocosdenshion_module
require "cclibs.cocosdenshion.DeprecatedCocosDenshionClass"
require "cclibs.cocosdenshion.DeprecatedCocosDenshionFunc"

-- register_extension_module
require "cclibs.extension.DeprecatedExtensionClass"
require "cclibs.extension.DeprecatedExtensionEnum"
require "cclibs.extension.DeprecatedExtensionFunc"

-- register_network_module
require "cclibs.network.DeprecatedNetworkClass"
require "cclibs.network.DeprecatedNetworkEnum"
require "cclibs.network.DeprecatedNetworkFunc"

-- register_ui_moudle
if nil ~= ccui then
    require "cclibs.ui.DeprecatedUIEnum"
    require "cclibs.ui.DeprecatedUIFunc"
end

-- cocosbuilder
require "cclibs.cocosbuilder.CCBReaderLoad"

-- physics3d
require "cclibs.physics3d.physics3d-constants"

if CC_USE_FRAMEWORK then
    require "cclibs.framework.init"
end

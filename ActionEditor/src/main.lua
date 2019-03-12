------------------------------------------------------
-- Name : Lua入口
-- Author : Reyn
-- Date : 2019.01.09
------------------------------------------------------

--使用Cocos框架
CC_USE_FRAMEWORK = true

--禁用显式全局注册
CC_DISABLE_GLOBAL = true

--设计尺寸
CC_DESIGN = {
    WIDTH = 1366,
    HEIGHT = 768,
    SCALE = 1.0,
    RATIO = 1.34,
    WINDOW_SCALE = 1.0,
    SHOW_FPS = false,
    GAME_FONT = 'Font/GameFont.ttf'
}

--适配尺寸规则
CC_DESIGN_RESOLUTION = {
    width  = CC_DESIGN.WIDTH  / CC_DESIGN.SCALE,
    height = CC_DESIGN.HEIGHT / CC_DESIGN.SCALE,
    autoscale = 'FIXED_HEIGHT',
    callback  = function(framesize)
        local ratio = framesize.width / framesize.height
        if ratio <= CC_DESIGN.RATIO then
            -- iPad 768*1024(1536*2048) is 4:3 screen
            return {autoscale = 'FIXED_WIDTH'}
        end
    end
}

--引用路径
cc.FileUtils:getInstance():setPopupNotify(false)
local plat = cc.Application:getInstance():getTargetPlatform()
local path = plat == 0 and {'../../src/', '../../res/'} or {'src/', 'res/'}
for i,v in ipairs(path) do
    cc.FileUtils:getInstance():addSearchPath(v)
end

--设置窗口显示尺寸
if plat == 0 then
    local director  = cc.Director:getInstance()
    local glView    = director:getOpenGLView()
    glView:setFrameSize(CC_DESIGN.WIDTH * CC_DESIGN.WINDOW_SCALE, CC_DESIGN.HEIGHT * CC_DESIGN.WINDOW_SCALE)
    director:setOpenGLView(glView)
end

----------------------------------------------------
require('cclibs.init')
require('game.LuaUtil')

local function main()
    math.randomseed((os.time()) * 1000)
    cc.exports.EditorScene = cc.Scene:create()
    display.runScene(EditorScene)

    local errorText = ccui.Text:create('', CC_DESIGN.GAME_FONT, 16)
    errorText:setTextColor(cc.c4b(255, 0, 0, 255))
    errorText:setPosition(display.center)
    EditorScene:addChild(errorText, 9999)
    EditorScene.displayError = function(msg)
        errorText:setString(msg)
    end

    cc.Director:getInstance():setDisplayStats(CC_DESIGN.SHOW_FPS)

    cc.exports.Game = require('game.Game'):new()
    Game:run()
end

--保存错误日志
local function saveError(msg)
    local f = io.open('error.log', 'a+')
    if not f then return end
    local date = ">>>Date: " .. tostring(os.date("%Y-%m-%d %H:%M:%S") .. '\n')
    f:write(date .. msg ..'\n<<<\n\n')
    f:close()
end

--错误跟踪
__G__TRACKBACK__ = function (msg)
    local msg = debug.traceback(msg, 3)
    saveError(msg)
    EditorScene.displayError(msg)
    return msg
end

xpcall(main, __G__TRACKBACK__)
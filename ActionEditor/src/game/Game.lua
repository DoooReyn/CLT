local Game = class('Game')

function Game:ctor()
end

function Game:run()
    local LoadingLayer = require('game.views.LoadingLayer'):create()
    EditorScene:addChild(LoadingLayer)
end

-- 创建提示节点
local function _createTipNode(tip, isInfo)
    local Text_Tip = ccui.Text:create(tip, CC_DESIGN.GAME_FONT, 20)
    Text_Tip:setName('Text_Tip')
    Text_Tip:setTextColor(isInfo and cc.YELLOW or cc.RED)
    Text_Tip:setPosition(display.cx, display.height - 30)
    local fadeTime = isInfo and 2 or 3
    Text_Tip:runAction(cc.Sequence:create(
        cc.FadeOut:create(fadeTime),
        cc.RemoveSelf:create()
    ))
    return Text_Tip
end

-- 展示消息节点
function Game:PushInfoTip(tip)
    EditorScene:removeNode('Text_Tip')
    EditorScene:addChild(_createTipNode(tip, true), 998)
end

-- 展示警告节点
function Game:PushWarnTip(tip)
    EditorScene:removeNode('Text_Tip')
    EditorScene:addChild(_createTipNode(tip, false), 998)
end

return Game
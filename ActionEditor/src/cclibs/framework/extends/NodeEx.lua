--[[

Copyright (c) 2011-2014 chukong-inc.com

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

local Node = cc.Node

function Node:add(child, zorder, tag)
    if tag then
        self:addChild(child, zorder, tag)
    elseif zorder then
        self:addChild(child, zorder)
    else
        self:addChild(child)
    end
    return self
end

function Node:addTo(parent, zorder, tag)
    if tag then
        parent:addChild(self, zorder, tag)
    elseif zorder then
        parent:addChild(self, zorder)
    else
        parent:addChild(self)
    end
    return self
end

function Node:removeSelf()
    self:removeFromParent()
    return self
end

function Node:align(anchorPoint, x, y)
    self:setAnchorPoint(anchorPoint)
    return self:move(x, y)
end

function Node:show()
    self:setVisible(true)
    return self
end

function Node:hide()
    self:setVisible(false)
    return self
end

function Node:move(x, y)
    if y then
        self:setPosition(x, y)
    else
        self:setPosition(x)
    end
    return self
end

function Node:moveTo(args)
    transition.moveTo(self, args)
    return self
end

function Node:moveBy(args)
    transition.moveBy(self, args)
    return self
end

function Node:fadeIn(args)
    transition.fadeIn(self, args)
    return self
end

function Node:fadeOut(args)
    transition.fadeOut(self, args)
    return self
end

function Node:fadeTo(args)
    transition.fadeTo(self, args)
    return self
end

function Node:rotate(rotation)
    self:setRotation(rotation)
    return self
end

function Node:rotateTo(args)
    transition.rotateTo(self, args)
    return self
end

function Node:rotateBy(args)
    transition.rotateBy(self, args)
    return self
end

function Node:scaleTo(args)
    transition.scaleTo(self, args)
    return self
end

function Node:onUpdate(callback)
    self:scheduleUpdateWithPriorityLua(callback, 0)
    return self
end

Node.scheduleUpdate = Node.onUpdate

function Node:onNodeEvent(eventName, callback)
    if "enter" == eventName then
        self.onEnterCallback_ = callback
    elseif "exit" == eventName then
        self.onExitCallback_ = callback
    elseif "enterTransitionFinish" == eventName then
        self.onEnterTransitionFinishCallback_ = callback
    elseif "exitTransitionStart" == eventName then
        self.onExitTransitionStartCallback_ = callback
    elseif "cleanup" == eventName then
        self.onCleanupCallback_ = callback
    end
    self:enableNodeEvents()
end

function Node:enableNodeEvents()
    if self.isNodeEventEnabled_ then
        return self
    end

    self:registerScriptHandler(function(state)
        if state == "enter" then
            self:onEnter_()
        elseif state == "exit" then
            self:onExit_()
        elseif state == "enterTransitionFinish" then
            self:onEnterTransitionFinish_()
        elseif state == "exitTransitionStart" then
            self:onExitTransitionStart_()
        elseif state == "cleanup" then
            self:onCleanup_()
        end
    end)
    self.isNodeEventEnabled_ = true

    return self
end

function Node:disableNodeEvents()
    self:unregisterScriptHandler()
    self.isNodeEventEnabled_ = false
    return self
end

----------------------------------------------
-- Event
--
function Node:addEvent(eventName, handler)
    if not self._eventPool then
        self._eventPool = EventPool.new()
    end
    self._eventPool:push(eventName, handler)
end

function Node:delEvent(eventName)
    if not self._eventPool then
        return
    end
    self._eventPool:pop(eventName)
end

function Node:delAllEvent()
    if not self._eventPool then
        return
    end
    self._eventPool:cleanup()
end
----------------------------------------------

----------------------------------------------
-- Timer
--
function Node:addTimer(timer, func, interval, isonce)
    self._timers = checktable(self._timers)
    if self._timers[timer] then
        self:delTimer(timer)
    end
    self._timers[timer] = timerMgr:add(func, interval, false, isonce)
end

function Node:delTimer(timer)
    if not self._timers or not self._timers[timer] then
        return
    end
    timerMgr:del(self._timers[timer])
    self._timers[timer] = nil
end

function Node:delAllTimer()
    if not self._timers then
        return
    end
    for k, v in pairs(self._timers) do
        timerMgr:del(v)
    end
    self._timers = nil
end
----------------------------------------------

function Node:onEnter()
end

function Node:onExit()
end

function Node:onEnterTransitionFinish()
end

function Node:onExitTransitionStart()
end

function Node:onCleanup()
end

function Node:onEnter_()
    self:onEnter()
    if not self.onEnterCallback_ then
        return
    end
    self:onEnterCallback_()
end

function Node:onExit_()
    self:onExit()
    if not self.onExitCallback_ then
        return
    end
    self:onExitCallback_()
end

function Node:onEnterTransitionFinish_()
    self:onEnterTransitionFinish()
    if not self.onEnterTransitionFinishCallback_ then
        return
    end
    self:onEnterTransitionFinishCallback_()
end

function Node:onExitTransitionStart_()
    self:onExitTransitionStart()
    if not self.onExitTransitionStartCallback_ then
        return
    end
    self:onExitTransitionStartCallback_()
end

function Node:onCleanup_()
    self:onCleanup()
    self:delAllTimer()
    self:delAllEvent()
    if not self.onCleanupCallback_ then
        return
    end
    self:onCleanupCallback_()
end

---------------------------------
--@description: 抖动效果
-- @param: tag 标记
-- @param: useTime 总共用时
-- @param: span 最大偏移量
-- @param: times 抖动次数
-- @param: cFun 毁掉函数
--
function Node:shake(tag, useTime, span, times, cFun)
    if not self:getActionByTag(tag) then
        local pos   = cc.p(self:getPositionX(), self:getPositionY())
        local act   = {}
        local times = 10
        local intc = span.x == 0 and useTime/span.y or useTime/span.x
        for i = 1, times, 1 do
            local intv  = span.x == 0 and span.y/2/i * intc or span.x/2/i * intc
            act[#act+1]   = cc.MoveBy:create(intv, cc.p(span.x/2/i,  span.y/2/i))
            act[#act+1] = act[#act]:reverse() 
            act[#act+1] = cc.MoveBy:create(intv, cc.p(-span.x/2/i,-span.y/2/i))
            act[#act+1] = act[#act]:reverse() 
        end
        act[#act+1] = cc.CallFunc:create(function() self:setPosition(pos) end)
        if cFun then
            act[#act+1] = cc.CallFunc:create(cFun)
        end
        local sq = cc.Sequence:create(act)
        sq:setTag(tag)
        self:runAction(sq)
    end 
end

-------------------------------------------------
--@description: 振动动作
-- @param node  : 作用节点
-- @param time  : 每个动作的时长
-- @param phase : 最大振幅
-- @param loop  : 振动次数
-- 
function Node:rock(time, phase, loop)
    time  = time or 0.03
    phase = phase or 4
    loop  = loop or 4
    local arr = {}
    for i=1, loop do
        local a1 = cc.JumpBy:create(time, cc.p(0,phase/i), 0, 1)
        local a2 = cc.JumpBy:create(time, cc.p(phase/i,0), 0, 1)
        local a3 = cc.JumpBy:create(time, cc.p(0,-phase/i), 0, 1)
        local a4 = cc.JumpBy:create(time, cc.p(-phase/i,0), 0, 1)
        table.insert(arr, a1)
        table.insert(arr, a2)
        table.insert(arr, a3)
        table.insert(arr, a4)
    end
    self:runAction(cc.Sequence:create(arr))
end

--------------------------------------------------
-- 遍历节点设置文本
--
function Node:setTextFontReverse()
    local children = self:getChildren()
    if #children > 0 then 
        for _, control in ipairs(children) do
            local type = control:getDescription()
            if type == 'Label' or type == 'Text' then
                control:setString(control:getString())
            elseif type == 'Button' then
                control:setTitleFontName(Rx.GameFont)
                local render = control:getTitleRenderer()
                if render then
                    render:enableTextEffect()
                end
            end
            control:setTextFontReverse()
        end
    end
end

--开启文本特效
function Node:enableTextEffect()
    if Rx.FontConfig.SetShadow and self.enableShadow then
        local shadow = Rx.FontConfig.Shadow
        self:enableShadow(shadow.color, shadow.size)
    end
    if Rx.FontConfig.SetOutline and self.enableOutline then
        local outline = Rx.FontConfig.Outline
        self:enableOutline(outline.color, outline.size)
    end
end

---------------------------------
--@description: 是否精灵
--
function Node:isSprite()
    return string.find(self:getDescription(), 'Sprite') or string.find(self:getDescription(), 'Label')
end

---------------------------------
--@description: 设置高亮
--@param: highlight 是否高亮
--@param: scale 高亮倍数
--
function Node:setHighLight(highlight, scale)
    if highlight then
        if shaderEffect then
            shaderEffect:setAddHighLight(self, scale)
        end
    else
        if shaderEffect then
            shaderEffect:removeShader(self)
        end
    end
end

--设置深度高亮
function Node:setHighLightRecursive(highlight, scale)
    self:setHighLight(highlight, scale)
    local children = self:getChildren()
    for _, v in ipairs(children) do
        v:setHighLightRecursive(highlight, scale)
    end
end

-------------------------------------------
--@description: 执行一次高亮动作后恢复正常
--@param: isSprite 是否精灵
--@param: tag 标记
--@param: time 总共用时
--
function Node:setHighLightOnce(tag, time)
    if not self:getActionByTag(tag) then
        self:setHighLight(true)
        local delay = cc.DelayTime:create(time)
        local callf = cc.CallFunc:create(function()
            self:setHighLight(false)
        end)
        local act = cc.Sequence:create(delay,callf)
        act:setTag(tag)
        self:runAction(act)
    end
end

---------------------------------
--@description: 设置灰色
--@param: isGray 是否置灰
--@param: rgb 灰色对比度
--
function Node:setGray(isGray, rgb)
    if isGray then
        if shaderEffect then
            shaderEffect:setAddGray(self, rgb)
        end
    else
        if shaderEffect then
            shaderEffect:removeShader(self)
        end
    end
end

--设置深度置灰
function Node:setGrayRecursive(isGray, rgb)
    self:setGray(isGray, rgb)
    local children = self:getChildren()
    for _, v in ipairs(children) do
        v:setGrayRecursive(isGray, rgb)
    end
end

--获得节点的中心点
function Node:getCenterPoint()
    local csize = self:getContentSize()
    local scale = cc.p(self:getScaleX(), self:getScaleY())
    return cc.p(csize.width*scale.x*0.5, csize.height*scale.y*0.5)
end

--获得节点的位置
function Node:getPositionEx()
    return cc.p(self:getPosition())
end

--移除节点
function Node:removeNode(name)
    local node = nil
    if type(name) == 'string' then
        node = self:getChildByName(name)
    elseif type(name) == 'number' then
        node = self:getChildByTag(name)
    end
    if node then
        node:removeFromParent()
    end
end

--获取宽度
function Node:getWidth()
    return self:getContentSize().width
end

--获取高度
function Node:getHeight()
    return self:getContentSize().height
end

-----------------------------------
--@description : 小红点创建
-- @num : 小红点数量提示
-- @pos : {xPer = x轴百分比, yPer = y轴百分比}
--
function Node:addRedDot(num, pos)
    self:removeNode('redrot')

    local imageview = ccui.ImageView:create("Images/UI/Common/common_132.png")
    imageview:setName('redrot')
    local x, y = self:getWidth(), self:getHeight()
    self:add(imageview, 99)
    if pos and type(pos) == 'table' and pos.xPer and pos.yPer then
        imageview:setPosition(x*pos.xPer, y*pos.yPer)
    else
        imageview:setPosition(x*0.88, y*0.8)
    end

    if num then
        local label = nil
        local x1 = imageview:getWidth()
        local y1 = imageview:getHeight()
        label = ccui.Text:create(num, Rx.GameFont, 20)
        label:setPosition(imageview:getCenterPoint())
        label:setName('finishnum')
        imageview:add(label)
    end
end

--移除小红点
function Node:removeRedDot()
    self:removeNode('redrot')
end

--设置小红点
function Node:setRedDot(set)
    if set then
        self:addRedDot()
    else
        self:removeRedDot()
    end
end

--查找节点
function Node:seekByName(name)
    local children = self:getChildren()
    for _, child in ipairs(children) do
        if child:getName() == name then
            return child
        else
            local ret = child:seekByName(name)
            if ret then return ret end
        end
    end
    return nil
end
function Node:seekByTag(tag)
    local children = self:getChildren()
    for _, child in ipairs(children) do
        if child:getTag() == tag then
            return child
        else
            local ret = child:seekByTag(tag)
            if ret then return ret end
        end
    end
    return nil
end
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

local Widget = ccui.Widget

Widget.addTouchEventListener_ = Widget.addTouchEventListener

function Widget:addTouchEventListener(callback)
    self.onTouchCallBack_ = callback
    self:addTouchEventListener_(handler(self, self.onTouchCallBack))
end

function Widget:onTouchCallBack(sender, event)
    if self.onTouchCallBack_ then
        self.onTouchCallBack_(sender, event)
    end
end

--添加点击事件
function Widget:addClickEvent(callfn, actionEnabled)
    self:setTouchEnabled(true)
    self:addTouchEventListener(function(sender, event)
        if actionEnabled then
            sender:onTouchAction(event)
        end
        if event == ccui.TouchEventType.ended then
            if callfn then
                callfn(sender)
            end
        end
    end)
end

function Widget:onTouch(callback)
    self:addTouchEventListener(function(sender, state)
        local event = {x = 0, y = 0}
        if state == 0 then
            event.name = "began"
        elseif state == 1 then
            event.name = "moved"
        elseif state == 2 then
            event.name = "ended"
        else
            event.name = "cancelled"
        end
        event.target = sender
        callback(event)
    end)
    return self
end

--'+' or '-' 长摁回调
function Widget:onLongPress(callback)
    self:addTouchEventListener(function(sender,event)
        soundMgr:playEffect('x011')
        if event == ccui.TouchEventType.began then
            local callback1 = function( ... )
                schedule(self, callback, 0.1)
            end
            performWithDelay(self, callback1, 0.5)
        end
        if event == ccui.TouchEventType.canceled or event == ccui.TouchEventType.ended then
            self:stopAllActions()
            return
        end
    end)
end

-------------------------------------------------
-- CCUI控件的点击缩放
--
local ZOOM_ACTION_TIME_STEP = 0.05
local ZOOM_SCALE = 0.07
local oScaleX, oScaleY = 1, 1
function Widget:onTouchAction(event)
    local s1 = cc.ScaleBy:create(ZOOM_ACTION_TIME_STEP, 1.0 + ZOOM_SCALE)
    if event == ccui.TouchEventType.began then
        oScaleX = self:getScaleX()
        oScaleY = self:getScaleY()
        self:stopAllActions()
        self:runAction(s1)
    elseif event == ccui.TouchEventType.ended or  event == ccui.TouchEventType.canceled  then
        self:stopAllActions()
        self:setScaleX(oScaleX)
        self:setScaleY(oScaleY)      
    end
end

-------------------------------------------------
-- @description : 短时间内只允许点击一次
-- @params : 恢复可点击状态的时长,默认0.5s
--
function Widget:setTouchOnce(resetTime)
    local isremoved = false
    self:registerScriptHandler(function(state)
        if state == "exit" then
            isremoved = true
        end
    end)
    resetTime = resetTime or 0.5
    self:setTouchEnabled(false)
    performWithDelay(self, function()
        if isremoved then 
            return
        end
        self:setTouchEnabled(true)
    end, resetTime)
end

ccui.Text._setString = ccui.Text.setString
function ccui.Text:setString(text)
    self:setFontName(CC_DESIGN.GAME_FONT)
    self:_setString(text)
end
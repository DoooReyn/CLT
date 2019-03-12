
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

local ListView = ccui.ListView
ListView._loadItemNumAtFirst = 5     --第一次加载多少个item
ListView._isScrolling = false        --是否在滚动中
ListView._isLoadingMoreItems = false --是否在加载新的子项

--第一次加载多少个item
function ListView:loadItemNumAtFirst(num)
    self._loadItemNumAtFirst = num
end

--每页加载多少个item
function ListView:loadItemNumPerPage(num)
    self._loadItemNumPerPage = num
end

---------------------------------------------------
--开启更多节点
-- node : 更多节点
-- scrollFn : 滚动回调
--
function ListView:enableMoreNode(node, scrollFn)
    self.Node_More = node
    self:onScroll(scrollFn)
end
--左右移动
function ListView:enableMoreNodeHori(node1, node2, scrollFn)
    self.Node_More_Left = node1
    self.Node_More_Right = node2
    self:onScroll(scrollFn)
end

--控制更多节点的显示
function ListView:refreshMoreNode(upOrdown)
    if self.Node_More then
        self.Node_More:setFlippedY(upOrdown)
    end
end
--控制更多水平节点的显示
function ListView:refreshMoreNodeHori(leftOrRight)
    if self.Node_More_Left and self.Node_More_Right then
        self.Node_More_Left:setVisible(leftOrRight)
        self.Node_More_Right:setVisible(not leftOrRight)
    end
end

--第一次加载子项
function ListView:loadItemsAtFirst()
    if self._loadingAct then
        self:stopAction(self._loadingAct)
        self._loadingAct = nil
        self._isLoadingMoreItems = false
    end

    self:setBounceEnabled(true)
    self:setInertiaScrollEnabled(false)

    --预先加载 self._loadItemNumAtFirst 个子项
    for i=1, self._loadItemNumAtFirst do
        self:__loadMoreItems()
    end

    --启动定时器去加载剩余子项
    local frameRate = 0.005
    self._frameRate = 0
    self._curLoadNum = 0
    self._isLoadingMoreItems = true
    self._loadingAct = schedule(self, function()
        self._frameRate = self._frameRate + frameRate
        local isOK = self:__loadMoreItems()
        if not isOK and self._loadingAct ~= nil then
            self:stopAction(self._loadingAct)
            self._isLoadingMoreItems = false
            self._loadingAct = nil
            self:setInertiaScrollEnabled(true)
            -- _print('self._frameRate : ', self._frameRate)
            self._frameRate = 0
        end
    end, frameRate)
end

--加载更多子项
function ListView:__loadMoreItems()
    if self.loadMoreItems then
        return self:loadMoreItems(#self:getItems()+1)
    end
    return false
end

--是否在滑动中
function ListView:isScrolling()
    return self._isScrolling
end

--监听点击事件
function ListView:onEvent(callback)
    self:addEventListener(function(sender, eventType)
        -- if self:isScrolling() or self._isLoadingMoreItems then
        --     return
        -- end
        local event = {}
        if eventType == 0 then
            event.name = "ON_SELECTED_ITEM_START"
        else
            event.name = "ON_SELECTED_ITEM_END"
        end
        event.target = sender
        if callback then
            callback(event)
        end
    end)
    return self
end

--监听滚动事件
function ListView:onScroll(callback)
    self:addScrollViewEventListener(function(sender, eventType)
        local event = {}
        if eventType == 0 then
            event.name = "SCROLL_TO_TOP"
            self:refreshMoreNode(true)
        elseif eventType == 1 then
            event.name = "SCROLL_TO_BOTTOM"
            self:refreshMoreNode(false)
        elseif eventType == 2 then
            event.name = "SCROLL_TO_LEFT"
            self:refreshMoreNodeHori(true)
        elseif eventType == 3 then
            event.name = "SCROLL_TO_RIGHT"
            self:refreshMoreNodeHori(false)
        elseif eventType == 4 then
            event.name = "SCROLLING"
            self._isScrolling = true
            self:refreshMoreNode(true)
        elseif eventType == 5 then
            event.name = "BOUNCE_TOP"
            self:refreshMoreNode(true)
        elseif eventType == 6 then
            event.name = "BOUNCE_BOTTOM"
            self:refreshMoreNode(false)
        elseif eventType == 7 then
            event.name = "BOUNCE_LEFT"
            self:refreshMoreNodeHori(true)
        elseif eventType == 8 then
            event.name = "BOUNCE_RIGHT"
            self:refreshMoreNodeHori(false)
        elseif eventType == 9 then
            event.name = "CONTAINER_MOVED"
            self._isScrolling = true
        elseif eventType == 10 then
            event.name = "AUTOSCROLL_ENDED"
            self._isScrolling = false
        end
        -- _print('onScroll : ', event.name)
        event.target = sender
        if callback then
            callback(event)
        end
    end)
    return self
end

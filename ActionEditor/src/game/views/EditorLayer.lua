------------------------------------------------------
-- Name : 编辑器层
-- Author : Reyn
-- Date : 2018.12.21
------------------------------------------------------

local EditorLayer = class('EditorLayer', require('game.views.LayerBase'))

-- 编辑器层初始化
function EditorLayer:init()
    self.csbName       = 'EditorLayer'      -- csb名称
    self.bgColor       = cc.c3b(20,40,80)   -- 背景颜色
    self.curMapId      = 1	                -- 当前地图ID
    self.curLoadItem   = nil	            -- 当前选中的编辑器选项
    self.curSelAniRect = nil	            -- 当前选中的动画
end

-- 初始化UI
function EditorLayer:initUI()
    self:initKeyBoard()
    self:initCanvasMap()
    self:initCanvasAnimation()
    self:initCanvasGroup()
    self:initDockerLeft()
    self:initDockerGeneral()
    self:initDirListItem()
    self:initActListItem()
    self:initFrameListItem()
    self:initBlendListItem()
    self:initFrameListView()
    self:initDockerSetting()
    self:loadEitorItems()
    self:resetSetting()
end

-- 初始化当前帧列表
function EditorLayer:initFrameListView()
    self.ListView_Frame = self.csbNode:seekByName('ListView_Frame')
    self.ListView_Frame:removeAllItems()
end

-- 加载当前帧列表
function EditorLayer:loadFrameListItems()
    self.ListView_Frame:removeAllItems()

    local current_frame_info = self:getCurrentFrame()
    if not current_frame_info then return end

    for i=1, current_frame_info.num do
        local from  = current_frame_info.from + i - 1
        local frame = string.format(current_frame_info.format, from)
        local item  = self.ListItem_Frame:clone()
        item:seekByName('Text_Value'):setString(frame)
        item.frame  = frame
        self.ListView_Frame:pushBackCustomItem(item)
    end

    self.ListView_Frame:stopAllActions()
    schedule(self.ListView_Frame, function()
        self:refreshDisplayFrame()
    end, current_frame_info.interval)
end

-- 刷新当前显示的帧
function EditorLayer:refreshDisplayFrame()
    if not self.curSelAniRect then return end
    local aniNode = self.curSelAniRect:seekByName('AnimationNode')
    local spriteFrame = aniNode:getSpriteFrame()
    if not spriteFrame then return end
    
    local items = self.ListView_Frame:getItems()
    for i, v in ipairs(items) do
        local frame = display.getSpriteFrame(v.frame)
        v:seekByName('Text_Value'):setTextColor( EditorConfig.GetListItemColor(spriteFrame == frame) )
    end
end

-- 初始化键盘事件
function EditorLayer:initKeyBoard()
    local function onKeyPressed(keyCode)
        print('press key: ', keyCode)
        if keyCode == 1 then
            --暂停地图移动
            self:stopMoveMap()
            return
        elseif keyCode == 21 then
            --地图复位
            self:resetMoveMap()
            return
        end

        if not self.curSelAniRect then 
            return
        end
        if not table.inside({26,27,28,29}, keyCode) then
            return
        end
        
        local isAnimation = self.curSelAniRect:getDescription() == 'Layout'
        local offset = cc.p(0,0)
        local current_frame_info = {}
        if isAnimation then
            current_frame_info = self:getCurrentFrame()
            offset = clone(current_frame_info.offset)
        else
            current_frame_info.offset = offset
        end
        if keyCode == 26 then
            -- 左
            offset.x = current_frame_info.offset.x-1
        end
        if keyCode == 27 then
            -- 右
            offset.x = current_frame_info.offset.x+1
        end
        if keyCode == 28 then
            -- 上
            offset.y = current_frame_info.offset.y+1
        end
        if keyCode == 29 then
            -- 下
            offset.y = current_frame_info.offset.y-1
        end
        if isAnimation then
            self:modifyCurrentFrame({offset = offset})
        else
            local oriPos = cc.p(self.curSelAniRect:getPosition())
            local finPos = cc.pAdd(oriPos, offset)
            self.curSelAniRect:setPosition(finPos)
        end

        if self.isLongPressed then
            return
        end
        local time = 0
        self:scheduleUpdate(function(dt)
            time = time + dt
            if time > 0.3 then
                self.isLongPressed = true
                onKeyPressed(keyCode)
            end
        end)
    end

    local function onKeyReleased(keyCode)
        self:unscheduleUpdate()
        self.isLongPressed = false
    end

    local listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler(onKeyPressed, cc.Handler.EVENT_KEYBOARD_PRESSED)
    listener:registerScriptHandler(onKeyReleased, cc.Handler.EVENT_KEYBOARD_RELEASED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, self)
end

--重置地图位置
function EditorLayer:resetMoveMap()
    self:stopMoveMap()
    self.Canvas_Map:setPosition(0, display.height)
end

--停止移动地图
function EditorLayer:stopMoveMap()
    self.isMapMoving = false
    if self.mapActHandle then
        self.Canvas_Map:stopAction(self.mapActHandle)
        self.mapActHandle = nil
    end
end

--开始移动地图
function EditorLayer:startMoveMap(dir)
    local normal = self.MapMoveSpeed
    local slash = normal
    local keymap = {
        [9] = cc.p(-slash, slash),     --左上
        [8] = cc.p(0, normal),         --上
        [7] = cc.p(slash, slash),      --右上
        [6] = cc.p(-normal, 0),        --左
        [4] = cc.p(normal, 0),         --右
        [3] = cc.p(-slash, -slash),    --左下
        [2] = cc.p(0, -normal),        --下
        [1] = cc.p(slash, -slash),     --右下
    }
    local to = keymap[dir]
    self.isMapMoving = true
    local width = self.Canvas_Map:getWidth()
    local height = self.Canvas_Map:getHeight()
    self.mapActHandle = self.Canvas_Map:runAction(
        cc.RepeatForever:create(
            cc.Sequence:create(
                cc.CallFunc:create(function()
                    local x, y = self.Canvas_Map:getPosition()
                    x = x + to.x
                    y = y + to.y
                    if x > 0 then
                        Game:PushWarnTip('地图已到达左边界')
                        self:stopMoveMap()
                    elseif y < display.height then
                        Game:PushWarnTip('地图已到达上边界')
                        self:stopMoveMap()
                    elseif x < -width+display.width then
                        Game:PushWarnTip('地图已到达右边界')
                        self:stopMoveMap()
                    elseif y > height-display.height then
                        Game:PushWarnTip('地图已到达下边界')
                        self:stopMoveMap()
                        return
                    end
                end),
                cc.MoveBy:create(1, to)
            )
        )
    )
end

-- 初始化地图画布
function EditorLayer:initCanvasMap()
    self.Docker_Map = self.csbNode:seekByName('Docker_Map')
    self.ListView_Map = self.Docker_Map:seekByName('ListView_Map')

    self.Canvas_Map = ccui.Layout:create()
    self.Canvas_Map:setPosition(0, display.height)
    self.Canvas_Map:setAnchorPoint(cc.p(0,1))
    self.Canvas_Map:setContentSize(display.size)
    self.Canvas_Map:setTouchEnabled(true)
    self.Canvas_Map:addTouchEventListener(function(sender, event)
        if event == ccui.TouchEventType.began then            
            self.curSelAniRect = nil
            self:resetSetting()
            sender.pre_pos = cc.p(sender:getTouchBeganPosition())
            sender.width = sender:getWidth() - display.width
            sender.height = sender:getHeight()
        elseif event == ccui.TouchEventType.moved then
            local move_pos = cc.p(sender:getTouchMovePosition())
            local cur_pos = cc.pAdd(cc.p(sender:getPosition()), cc.pSub(move_pos, sender.pre_pos))
            if cur_pos.x > 0 then
                cur_pos.x = 0
            end
            if cur_pos.y > sender.height then
                cur_pos.y = sender.height
            end
            if cur_pos.x < -sender.width then
                cur_pos.x = -sender.width
            end
            if cur_pos.y < display.height then
                cur_pos.y = display.height
            end
            sender.pre_pos = move_pos
            sender:setPosition(cur_pos)
        end
    end)
    self.Canvas_Map:addTo(self.csbNode, -1)

    self.TextField_MoveSpeed = self.Docker_Map:seekByName('TextField_MoveSpeed')
    self.MapMoveSpeed = EditorConfig.MapMoveSpeed
    self.TextField_MoveSpeed:setString(self.MapMoveSpeed)
    setCursorField(self.TextField_MoveSpeed, true, true, function(sender, event)
        if event == ccui.TextFiledEventType.detach_with_ime then
            local speed = tonumber(sender:getString())
            if speed and speed >= 1 then
                self.MapMoveSpeed = speed
                self:stopMoveMap()
            end
        elseif event == ccui.TextFiledEventType.insert_text then
            local speed = tonumber(sender:getString())
            if not speed or speed < 1 then
                sender:setString(self.MapMoveSpeed)
            end
        end
    end)

    for i=1, 9 do
        local Text_Dir = self.Docker_Map:seekByName('Text_Dir_'..i)
        Text_Dir.dir = i
        Text_Dir:addClickEvent(function(sender, event)
            if sender.dir == 5 then
                self:stopMoveMap()
            else
                self:stopMoveMap()
                self:startMoveMap(sender.dir)
            end
        end)
    end

    self:initMapListItem()
    self:loadMapItems()
    self:loadMap(self.curMapId)
end

-- 加载地图子项
function EditorLayer:loadMapItems()
    self.curMapId = EditorConfig.Map.Blocks[1][1]
    for _, map in ipairs(EditorConfig.Map.Blocks) do
        local item = self.ListItem_Map:clone()
        item.mapId = map[1]
        item:seekByName('Text_Value'):setString(item.mapId)
        item:seekByName('Text_Value'):setTextColor(EditorConfig.GetListItemColor(item.mapId == self.curMapId))
        self.ListView_Map:pushBackCustomItem(item)
    end
end

-- 加载地图
function EditorLayer:loadMap(mapId)
    local count = #self.Canvas_Map:getChildren()
    if count == 0 or (count > 0 and self.curMapId ~= mapId) then
        self.Canvas_Map:stopAllActions()
        self.Canvas_Map:removeAllChildren()
        self.Canvas_Map:setPosition(0, display.height)

        self.curMapId = mapId
        local mapCfg = EditorConfig.Map.Blocks[mapId]
        local map_width = mapCfg[3]*512
        local map_height = mapCfg[2]*512
        self.Canvas_Map:setContentSize(map_width, map_height)

        local delayTime = 0.05
        local actions = {}
        for row=1, mapCfg[2] do
            for col=1, mapCfg[3] do
                if row > 2 then delayTime = 0.1 end
                local a1 = cc.DelayTime:create(delayTime)
                local a2 = cc.CallFunc:create(function()
                    local filepath = EditorConfig.Map.GetBlock(mapId, row, col)
                    local mapNode = cc.Sprite:create(filepath)
                    if mapNode then
                        mapNode:setAnchorPoint(cc.p(0,1))
                        local px = (col-1)*EditorConfig.Map.BlockWidth
                        local py = map_height-(row-1)*EditorConfig.Map.BlockHeight
                        mapNode:setPositionX(px)
                        mapNode:setPositionY(py)
                        mapNode:addTo(self.Canvas_Map)
                    end                
                end)
                local act = cc.Sequence:create(a1, a2)
                actions[#actions+1] = act
            end
        end
        self.Canvas_Map:runAction(cc.Sequence:create(actions))
    end
end

-- 初始化动画画布
function EditorLayer:initCanvasAnimation()
    self.Canvas_Animation = ccui.Layout:create()
    self.Canvas_Animation:setContentSize(display.size)
    self.Canvas_Animation:setPosition(0, 0)
    self.Canvas_Animation:addTo(self.csbNode, -1)
end

-- 初始化组动画画布
function EditorLayer:initCanvasGroup()
    self.Canvas_Group = ccui.Layout:create()
    self.Canvas_Group:setContentSize(display.size)
    self.Canvas_Group:setPosition(0, 0)
    self.Canvas_Group:addTo(self.csbNode, 0)
end

-- 初始化左侧面板
function EditorLayer:initDockerLeft()
    self.Docker_LoadItem = self.csbNode:seekByName('Docker_LoadItem')
    self.Btn_LoadTop     = self.csbNode:seekByName('Btn_LoadTop')
    self.ListView_Load   = self.csbNode:seekByName('ListView_Load')
    self.Docker_ListItem = self.csbNode:seekByName('Docker_ListItem')
    self.Btn_ListTop     = self.csbNode:seekByName('Btn_ListTop')
    self.ListView_List   = self.csbNode:seekByName('ListView_List')
    self.Docker_Left_FixX = self.Docker_ListItem:getWidth()
    self.Docker_Left_FixY = self.Docker_ListItem:getPositionY()
    self.Docker_LoadItem:setPositionX(0)
    self.Docker_ListItem:setPositionX(-self.Docker_Left_FixX)
    
    self:initBtnTop()
    self:initEditorLoadItem()
    self:initEditorListItem()
end

-- 初始化通用面板
function EditorLayer:initDockerGeneral()
    self.Docker_General = self.csbNode:seekByName('Docker_General')

    -- 清屏
    local Btn_Clear = self.Docker_General:seekByName('Btn_Clear')
    Btn_Clear:addClickEvent(function(sender, event)
        sender:setTouchOnce(1)
        self.curSelAniRect = nil
        self:resetSetting()
        self.Canvas_Animation:removeAllChildren()
        self.ListView_Ani:removeAllItems()
    end)

    -- 全部暂停
    local Btn_All_Pause = self.Docker_General:seekByName('Btn_All_Pause')
    Btn_All_Pause:addClickEvent(function(sender, event)
        sender:setTouchOnce(1)
        self:pauseAllAnimations()
    end)

    -- 全部开始
    local Btn_All_Start = self.Docker_General:seekByName('Btn_All_Start')
    Btn_All_Start:addClickEvent(function(sender, event)
        sender:setTouchOnce(1)
        self:startAllAnimations()
    end)

    -- 全部保存
    local Btn_All_Save = self.Docker_General:seekByName('Btn_All_Save')
    Btn_All_Save:addClickEvent(function(sender, event)
        sender:setTouchOnce(1)
        self:saveAllAnimations()
    end)

    -- 动画列表
    local Btn_All_Anis = self.Docker_General:seekByName('Btn_All_Anis')
    self.ListView_Ani = self.Docker_General:seekByName('ListView_Ani')
    self.ListView_Ani:removeAllItems()
    self:initAniListItem()

    --添加到组
    self.Text_AddToGroup = self.Docker_General:seekByName('Text_AddToGroup')
    self.Text_AddToGroup:setVisible(false)
    self.Text_AddToGroup:addClickEvent(function(sender, event)
        self:addToGroup()
    end)
    self.Text_AddToGroup:onUpdate(function()
        self.Text_AddToGroup:setVisible(#self.ListView_Ani:getItems() > 0)
    end)

    -- 顺序列表
    local Btn_Seq = self.Docker_General:seekByName('Btn_Seq')
    self.ListView_Seq = self.Docker_General:seekByName('ListView_Seq')
    local Text_Start = Btn_Seq:seekByName('Text_Start')
    Text_Start:addClickEvent(function(sender, event)
        self:startAllSeqAnis()
    end)
    local Text_Pause = Btn_Seq:seekByName('Text_Pause')
    Text_Pause:addClickEvent(function(sender, event)
        self:stopAllSeqAnis()
    end)
    local Text_Clear = Btn_Seq:seekByName('Text_Clear')
    Text_Clear:addClickEvent(function(sender, event)
        self.ListView_Seq:removeAllItems()
    end)
    self.ListView_Seq:removeAllItems()
    self:initSeqListItem()
end

-- 开始全部动画
function EditorLayer:startAllAnimations()
    local children = self.ListView_Ani:getItems()
    for index, item in ipairs(children) do
        local animation_rect = self.Canvas_Animation:seekByName(item.name)
        if animation_rect and animation_rect:getDescription() == 'Layout' then
            AnimationRect:play(animation_rect)
            animation_rect:seekByName('AnimationNode'):setPosition(animation_rect.anipos)
        end
    end
end

-- 暂停全部动画
function EditorLayer:pauseAllAnimations()
    local children = self.ListView_Ani:getItems()
    for index, item in ipairs(children) do
        local animation_rect = self.Canvas_Animation:seekByName(item.name)
        if animation_rect and animation_rect:getDescription() == 'Layout' then
            AnimationRect:pause(animation_rect)
        end
    end
end

-- 保存全部动画
function EditorLayer:saveAllAnimations()
    local children = self.ListView_Ani:getItems()
    for index, item in ipairs(children) do
        local animation_rect = self.Canvas_Animation:seekByName(item.name)
        if animation_rect and animation_rect:getDescription() == 'Layout' then
            AnimationRect:save(animation_rect)
        end
    end
end

-- 初始化方向列表子项
function EditorLayer:initDirListItem()
    self.ListItem_Dir = self.csbNode:seekByName('ListItem_Dir')
    self.ListItem_Dir:addClickEvent(function(sender, event)
        sender:setTouchOnce(1)
        self:selectDirItem(sender.dir, true)
    end)
end

-- 初始化动作列表子项
function EditorLayer:initActListItem()
    self.ListItem_Act = self.csbNode:seekByName('ListItem_Act')
    self.ListItem_Act:addClickEvent(function(sender, event)
        sender:setTouchOnce(1)
        self:selectActItem(sender.act, true)
    end)
end

-- 初始化地图列表子项
function EditorLayer:initMapListItem()
    self.ListItem_Map = self.csbNode:seekByName('ListItem_Map')
    self.ListItem_Map:addClickEvent(function(sender, event)
        sender:setTouchOnce(1)
        self:selectMapItem(sender.mapId)
    end)
end

-- 初始化动画列表子项
function EditorLayer:initAniListItem()
    self.ListItem_Ani = self.csbNode:seekByName('ListItem_Ani')
    self.ListItem_Ani:addClickEvent(function(sender, event)
        sender:setTouchOnce(1)
        local item = self.Canvas_Animation:seekByName(sender.name)
        local description = item:getDescription()
        self.curSelAniRect = item
        if description == 'Layout' then
            self:loadSetting()
        elseif description == 'ImageView' then
            self.Docker_Setting:setVisible(false)
            self.ListView_Frame:setVisible(false)
            self.ListView_Frame:stopAllActions()
        end
        self:changeAniListItemColor(sender.name)
    end)
    
    local Btn_Del = self.ListItem_Ani:seekByName('Btn_Del')
    Btn_Del:addClickEvent(function(sender, event)
        local aniName = sender.name
        self:popOneAniItem(aniName)
        if self.curSelAniRect and self.curSelAniRect:getName() == aniName then
            self:resetSetting()
        end
        self.Canvas_Animation:removeNode(aniName)
    end)
    
    local Btn_Down = self.ListItem_Ani:seekByName('Btn_Down')
    Btn_Down:addClickEvent(function(sender, event)
        local aniName = sender.name
        local item = sender:getParent()
        local index = self.ListView_Ani:getIndex(item)
        if index == #self.ListView_Ani:getItems()-1 then
            return
        end

        local item_clone = item:clone()
        self.ListView_Ani:removeItem(index)
        self.ListView_Ani:insertCustomItem(item_clone, index+1)
        item_clone.name = aniName
        item_clone:seekByName('Btn_Del').name = aniName
        item_clone:seekByName('Btn_Down').name = aniName
        self.Canvas_Animation:seekByName(aniName):setLocalZOrder(index+1)
        
        local item_pre = self.ListView_Ani:getItem(index)
        self.Canvas_Animation:seekByName(item_pre.name):setLocalZOrder(index)
    end)
end

-- 初始化混合列表子项
function EditorLayer:initBlendListItem()
    self.ListItem_Blend_Src = self.csbNode:seekByName('ListItem_Blend_Src')
    self.ListItem_Blend_Dst = self.csbNode:seekByName('ListItem_Blend_Dst')
    self.ListItem_Blend_Src:addClickEvent(function(sender, event)
        self:selectBlendSrcItem(sender.glblend, true)
    end)
    self.ListItem_Blend_Dst:addClickEvent(function(sender, event)
        sender:setTouchOnce(1)
        self:selectBlendDstItem(sender.glblend, true)
    end)
end

-- 初始化当前帧列表子项
function EditorLayer:initFrameListItem()
    self.ListItem_Frame = self.csbNode:seekByName('ListItem_Frame')
    self.ListItem_Frame:addClickEvent(function(sender, event)
        self:selectFrameItem(sender.frame)
    end)
end

--初始化顺序播放列表子项
function EditorLayer:initSeqListItem()
    self.ListItem_Seq = self.csbNode:seekByName('ListItem_Seq')
    self.ListItem_Seq:addClickEvent(function(sender, event)
        self:startGroupAnimation(sender)
    end)

    local Btn_Del = self.ListItem_Seq:seekByName('Btn_Del')
    Btn_Del:addClickEvent(function(sender, event)
        self.ListView_Seq:stopAllActions()
        self:removeFromGroup(sender.name)
    end)
end

function EditorLayer:createGroupAnimation(group, delay)
    delay = delay or 0

    local maxTime = 0
    for _, v in ipairs(group) do
        maxTime = v.time > maxTime and v.time or maxTime
        
        local actInfo = v.frame
        local animate, aniNode = display.newAnimation(actInfo.format, actInfo.from, actInfo.num, actInfo.interval)
        if actInfo.glblend then
            aniNode:setBlendFunc({src = actInfo.glblend_src, dst = actInfo.glblend_dst})
        end
        aniNode:setScale(actInfo.scale)
        aniNode:setFlippedX(actInfo.flip)
        aniNode:setOpacity(actInfo.opacity)
        aniNode:setVisible(false)
        aniNode:setPosition(cc.pAdd(display.center, v.offset))

        local dltAct = cc.DelayTime:create(actInfo.delay + delay)
        local showAct= cc.Show:create()
        local aniAct = cc.Animate:create(animate)
        local rmvAct = cc.RemoveSelf:create()
        local animation = cc.Sequence:create(dltAct, showAct, aniAct, rmvAct)
        aniNode:runAction( animation )
        aniNode:addTo(self.Canvas_Group)
    end

    return maxTime
end

-- 播放组动画
function EditorLayer:playGroupAnimation(playFunc)
    Game:PushInfoTip( '正在播放组动画' )
    self.Canvas_Group:stopAllActions()
    self.Canvas_Group:removeAllChildren()
    self.Canvas_Animation:setVisible(false)

    local maxTime = playFunc()

    self.Canvas_Group:runAction(cc.Sequence:create(
        cc.DelayTime:create(maxTime+0.1),
        cc.CallFunc:create(function()
            self.Canvas_Animation:setVisible(true)
            self.Canvas_Group:removeAllChildren()
            Game:PushInfoTip( '组动画播放结束' )
        end)
    ))
end

-- 播放单项组动画
function EditorLayer:startGroupAnimation(sender)
    self:playGroupAnimation(function()
        return self:createGroupAnimation(sender.group)
    end)
end

--播放顺序动画
function EditorLayer:startAllSeqAnis()
    self:playGroupAnimation(function()
        local maxTime = 0
        local items = self.ListView_Seq:getItems()
        for _,v in ipairs(items) do
            local time = self:createGroupAnimation(v.group, maxTime)
            maxTime = maxTime + time
        end
        return maxTime
    end)
end

--暂停顺序动画
function EditorLayer:stopAllSeqAnis()
    self.Canvas_Animation:setVisible(true)
    self.Canvas_Group:stopAllActions()
    self.Canvas_Group:removeAllChildren()
end

--添加顺序播放子项
function EditorLayer:addToGroup()
    local group = {}
    local items = self.ListView_Ani:getItems()
    for _, v in ipairs(items) do
        local animation_rect = self.Canvas_Animation:seekByName(v.name)
        if animation_rect and animation_rect:getDescription() == 'Layout' then
            local frame = animation_rect.animation:getActFrame(animation_rect.current_dir, animation_rect.current_act)
            local offset = frame.offset
            local time = frame.interval * frame.num
            table.insert(group, {frame = frame, offset = offset, time = time})
        end
    end

    local count = #self.ListView_Seq:getItems()
    local item = self.ListItem_Seq:clone()
    item.group = group
    item.name = 'Group'..(count+1)
    item:seekByName('Text_Value'):setString(item.name)
    item:seekByName('Btn_Del').name = item.name
    self.ListView_Seq:pushBackCustomItem(item)
end

--删除顺序播放子项
function EditorLayer:removeFromGroup(name)
    local children = self.ListView_Seq:getItems()
    for index, item in ipairs(children) do
        if item.name == name then
            self.ListView_Seq:removeItem(index-1)
            break
        end
    end
    self.ListView_Seq:refreshView()
end

-- 选中方向子项
function EditorLayer:selectDirItem(dir, apply)
    local items = self.ListView_Dir:getItems()
    for i, item in ipairs(items) do
        item:seekByName('Text_Value'):setTextColor(EditorConfig.GetListItemColor(dir == item.dir))
    end

    if self.curSelAniRect.current_dir == dir then
        return
    end
    
    if not apply then return end
    
    self.curSelAniRect.current_dir = dir
    local current_frame_info = self:getCurrentFrame()
    self:modifyCurrentFrame({
        interval = current_frame_info.interval, 
        scale = current_frame_info.scale, 
        delay = current_frame_info.delay,
        opacity = current_frame_info.opacity
    })
end

-- 选中动作子项
function EditorLayer:selectActItem(act, apply)
    local items = self.ListView_Act:getItems()
    for i, item in ipairs(items) do
        item:seekByName('Text_Value'):setTextColor(EditorConfig.GetListItemColor(act == item.act))
    end

    if self.curSelAniRect.current_act == act then
        return
    end
    
    if not apply then return end
    
    self.curSelAniRect.current_act = act
    local current_frame_info = self:getCurrentFrame()
    self:modifyCurrentFrame({
        interval = current_frame_info.interval, 
        scale = current_frame_info.scale, 
        delay = current_frame_info.delay, 
        opacity = current_frame_info.opacity
    })
end

-- 选中地图子项
function EditorLayer:selectMapItem(mapId)
    local items = self.ListView_Map:getItems()
    for i, item in ipairs(items) do
        item:seekByName('Text_Value'):setTextColor(EditorConfig.GetListItemColor(mapId == item.mapId))
    end
    self:loadMap(mapId)
end

-- 选中混合源子项
function EditorLayer:selectBlendSrcItem(glblend, apply)
    local items = self.ListView_Blend_Src:getItems()
    for i, item in ipairs(items) do
        local color = EditorConfig.GetListItemColor(glblend == item.glblend)
        item:seekByName('Text_Value'):setTextColor(color)
    end
    if not apply then return end
    self:modifyCurrentFrame({glblend_src = glblend})
end

-- 选中混合目子项
function EditorLayer:selectBlendDstItem(glblend, apply)
    local items = self.ListView_Blend_Dst:getItems()
    for i, item in ipairs(items) do
        local color = EditorConfig.GetListItemColor(glblend == item.glblend)
        item:seekByName('Text_Value'):setTextColor(color)
    end
    if not apply then return end
    self:modifyCurrentFrame({glblend_dst = glblend})
end

-- 选中当前帧子项
function EditorLayer:selectFrameItem(frame)
    if not self.curSelAniRect then return end
    local aniNode = self.curSelAniRect:seekByName('AnimationNode')
    aniNode:stopAllActions()
    local spriteFrame = display.getSpriteFrame(frame)
    if spriteFrame then
        aniNode:setSpriteFrame(spriteFrame)
    end
    self:changeFrameSelectColor(frame)
end

-- 更换当前选中帧子项的底色
function EditorLayer:changeFrameSelectColor(frame)
    local items = self.ListView_Frame:getItems()
    for i, v in ipairs(items) do
        v:seekByName('Text_Value'):setTextColor( EditorConfig.GetListItemColor(v.frame == frame) )
    end
end

-- 更换当前选中动画子项的底色
function EditorLayer:changeAniListItemColor(name)
    local items = self.ListView_Ani:getItems()
    for i, v in ipairs(items) do
        v:seekByName('Text_Value'):setTextColor( EditorConfig.GetListItemColor(v.name == name) )
    end
end

-- 推入动画列表子项
function EditorLayer:pushOneAniItem(aniName)
    local item = self.ListItem_Ani:clone()
    item.name = aniName
    item:seekByName('Text_Value'):setString(aniName)
    item:seekByName('Btn_Del').name = aniName
    item:seekByName('Btn_Down').name = aniName
    self.ListView_Ani:pushBackCustomItem(item)

    local count = #self.ListView_Ani:getItems()
    self.Canvas_Animation:seekByName(aniName):setLocalZOrder(count)
end

-- 推出动画列表子项
function EditorLayer:popOneAniItem(aniName)
    local children = self.ListView_Ani:getItems()
    for index, item in ipairs(children) do
        if item.name == aniName then
            self.ListView_Ani:removeItem(index-1)
            break
        end
    end
    self.ListView_Ani:refreshView()
end

-- 初始化编辑列表按钮
function EditorLayer:initBtnTop()
    self.Btn_ListTop:addClickEvent(function(sender, event)
       sender:setTouchOnce(1)
        self:moveIn(self.Docker_LoadItem)
        self:moveOut(self.Docker_ListItem)
    end)
end

-- 初始化设置面板
function EditorLayer:initDockerSetting()
    self.Docker_Setting = self.csbNode:seekByName('Docker_Setting')
    self.Text_Num_Value       = self.Docker_Setting:seekByName('Text_Num_Value')
    self.Text_Name_Value      = self.Docker_Setting:seekByName('Text_Name_Value')
    self.TextField_Rate       = self.Docker_Setting:seekByName('TextField_Rate')
    self.TextField_Scale      = self.Docker_Setting:seekByName('TextField_Scale')
    self.TextField_Opacity    = self.Docker_Setting:seekByName('TextField_Opacity')
    self.TextField_Delay      = self.Docker_Setting:seekByName('TextField_Delay')
    self.Text_Save            = self.Docker_Setting:seekByName('Text_Save')
    self.Text_Discard         = self.Docker_Setting:seekByName('Text_Discard')
    self.Text_Refresh         = self.Docker_Setting:seekByName('Text_Refresh')
    self.Text_Start           = self.Docker_Setting:seekByName('Text_Start')
    self.Text_Pause           = self.Docker_Setting:seekByName('Text_Pause')
    self.Text_Flip            = self.Docker_Setting:seekByName('Text_Flip')
    self.Text_Blend           = self.Docker_Setting:seekByName('Text_Blend')
    self.Text_Offset_Value    = self.Docker_Setting:seekByName('Text_Offset_Value')
    self.Text_Frame_Blend_Src = self.Docker_Setting:seekByName('Text_Frame_Blend_Src')
    self.Text_Frame_Blend_Dst = self.Docker_Setting:seekByName('Text_Frame_Blend_Dst')
    self.ListView_Dir         = self.Docker_Setting:seekByName('ListView_Dir')
    self.ListView_Act         = self.Docker_Setting:seekByName('ListView_Act')
    self.ListView_Blend_Src   = self.Docker_Setting:seekByName('ListView_Blend_Src')
    self.ListView_Blend_Dst   = self.Docker_Setting:seekByName('ListView_Blend_Dst')

    setCursorField(self.TextField_Rate, true, false)
    setCursorField(self.TextField_Scale, true, false)
    setCursorField(self.TextField_Opacity, true, false)
    setCursorField(self.TextField_Delay, true, false)

    self.Text_Save:addClickEvent(function(sender, event)
        self:saveSetting()
    end)
    self.Text_Discard:addClickEvent(function(sender, event)
        self:discardSetting()
    end)
    self.Text_Refresh:addClickEvent(function(sender, event)
        self:modifyCurrentFrame({})
        self:applySetting()
    end)
    self.Text_Start:addClickEvent(function(sender, event)
        AnimationRect:play(self.curSelAniRect)
        self.curSelAniRect:seekByName('AnimationNode'):setPosition(animation_rect.anipos)
    end)
    self.Text_Pause:addClickEvent(function(sender, event)
        AnimationRect:pause(self.curSelAniRect)
    end)
    self.Text_Flip:addClickEvent(function(sender, event)
        local current_frame_info = self:getCurrentFrame()
        if current_frame_info then
            self:modifyCurrentFrame({flip = not current_frame_info.flip})
        end
    end)
    self.Text_Blend:addClickEvent(function(sender, event)
        local current_frame_info = self:getCurrentFrame()
        if current_frame_info then
            self:modifyCurrentFrame({glblend = not current_frame_info.glblend})
        end
    end)
end

-- 获得当前帧数据
function EditorLayer:getCurrentFrame()
    if not self.curSelAniRect then return nil end
    local dirIndex, actIndex = self.curSelAniRect.current_dir, self.curSelAniRect.current_act
    return self.curSelAniRect.animation:getActFrame(dirIndex, actIndex)
end

-- 修改当前帧数据
function EditorLayer:modifyCurrentFrame(args)
    if not self.curSelAniRect then return end
    if not args then return end
    local current_frame_info = self:getCurrentFrame()
    if not current_frame_info then return end

    -- 处理帧率
    if args.interval then
        self.TextField_Rate:setString(args.interval)
    else
        local frame_rate = tonumber(self.TextField_Rate:getString())
        if frame_rate then args.interval = frame_rate end
    end

    -- 处理缩放
    if args.scale then
        self.TextField_Scale:setString(args.scale)
    else
        local scale = tonumber(self.TextField_Scale:getString())
        if scale then args.scale = scale end
    end

    -- 处理延迟
    if args.delay then
        self.TextField_Delay:setString(args.delay)
    else
        local delay = tonumber(self.TextField_Delay:getString())
        if delay then args.delay = delay end
    end

    -- 处理透明
    if args.opacity then
        self.TextField_Delay:setString(args.opacity)
    else
        local opacity = tonumber(self.TextField_Opacity:getString())
        if opacity then
            if opacity < 0 then
                opacity = 0
            end
            if opacity > 255 then
                opacity = 255
            end
            args.opacity = opacity 
        end
    end
    
    -- 应用到当前帧
    for k, v in pairs(args) do
        if current_frame_info[k] ~= nil then
            current_frame_info[k] = v
        end
    end

    local dirIndex, actIndex = self.curSelAniRect.current_dir, self.curSelAniRect.current_act
    self.curSelAniRect.animation:setActFrame(dirIndex, actIndex, current_frame_info)
    
    -- 显示并应用当前帧数据
    self:displayCurrentFrame()
    self:applySetting()
end

-- 初始化编辑器选项列表项
function EditorLayer:initEditorLoadItem()
    self.ListItem_Load = self.csbNode:seekByName('ListItem_Load')
    self.ListItem_Load:addClickEvent(function(sender, event)
        sender:setTouchOnce(1)
        self:moveIn(self.Docker_ListItem)
        self:moveOut(self.Docker_LoadItem)
        self:loadListItem(sender.data.dir)
        self.curLoadItem = sender
    end)
end

-- 初始化列表项
function EditorLayer:initEditorListItem()
    self.ListItem_List = self.csbNode:seekByName('ListItem_List')
    self.ListItem_List:addClickEvent(function(sender, event)
        sender:setTouchOnce(1)
        self:clickListItem(sender.data)
    end)
end

-- 加载编辑器选项列表
function EditorLayer:loadEitorItems()
    for _, v in ipairs(EditorConfig.LoadItemList) do
        local item = self.ListItem_Load:clone()
        item.data = v
        item:seekByName('Text_Btn'):setString(v.name)
        self.ListView_Load:pushBackCustomItem(item)
    end
end

-- 推入一项动画选项
function EditorLayer:pushOneListItem(data)
    local item = self.ListItem_List:clone()
    item:seekByName('Text_Btn'):setString(data)
    item.data = data
    self.ListView_List:pushBackCustomItem(item)
end

-- 加载具体列表项
function EditorLayer:loadListItem(dir)
    self.ListView_List:removeAllItems()

    local list_items = EditorLoadItems[dir]
    for i, v in ipairs(list_items) do
        self:pushOneListItem(v)
    end
    self.ListView_List:jumpToTop()
    self.ListView_List:refreshView()
end

-- 点击到具体列表项
function EditorLayer:clickListItem(item)
    if self.Canvas_Animation:seekByName(item) then
        Game:PushInfoTip(string.format('%s动画已加载', item))
        return
    end

    --加载动画或者图片
    local dir = self.curLoadItem.data.dir
    local luapath = string.format('game/const/%s/%s.lua', dir, item)
    if not cc.FileUtils:getInstance():isFileExist(luapath) then
        --加载图片
        local imagepath = string.format('Textures/Other/%s.png', item)
        if cc.FileUtils:getInstance():isFileExist(imagepath) then
            local Imageview = ccui.ImageView:create(imagepath)
            Imageview:addTo(self.Canvas_Animation, -1)
            Imageview:setTouchEnabled(true)
            Imageview:setPosition(display.center)
            Imageview:setName(item)
            Imageview:addTouchEventListener(function(sender, event)
                if event == ccui.TouchEventType.began then
                    sender.pre_pos = cc.p(sender:getTouchBeganPosition())
                    self.curSelAniRect = sender
                    self.Docker_Setting:setVisible(false)
                    self.ListView_Frame:setVisible(false)
                    self.ListView_Frame:stopAllActions()
                    self:changeAniListItemColor(item)
                elseif event == ccui.TouchEventType.moved then
                    local move_pos = cc.p(sender:getTouchMovePosition())
                    local cur_pos = cc.pAdd(cc.p(sender:getPosition()), cc.pSub(move_pos, sender.pre_pos))
                    sender.pre_pos = move_pos
                    sender:setPosition(cur_pos)
                end
            end)
            self:pushOneAniItem(item)
        else
            Game:PushWarnTip(string.format('创建%s图像失败', imagepath))
        end
        return
    end
    
    local file = string.format('game.const.%s.%s', dir, item)
    local animation = AnimationHelper:createWithFile(file)
    if not animation then
        Game:PushWarnTip(string.format('创建%s动画失败', item))
        return
    end

    -- 创建节点矩形框
    local animation_rect = ccui.Layout:create()
    animation_rect:setName(item)
    animation_rect:setAnchorPoint(display.CENTER)
    animation_rect:setPosition(display.center)
    animation_rect:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    animation_rect:setBackGroundColor(cc.BLACK)
    animation_rect:setBackGroundColorOpacity(10)
    animation_rect:addTo(self.Canvas_Animation)
    animation_rect.animation = animation
    animation_rect.current_dir = animation.dirs[1]
    animation_rect.current_act = 1
    animation_rect.current_scale = 1.0
    animation_rect.center = display.center

    -- 设置矩形框触摸事件
    animation_rect:setTouchEnabled(true)
    animation_rect:addTouchEventListener(function(sender, event)
        if event == ccui.TouchEventType.began then
            self.curSelAniRect = sender
            self:loadSetting()
            self:changeAniListItemColor(item)
        elseif event == ccui.TouchEventType.moved then
            --[[ 暂时关闭移动
                local move_pos = cc.p(sender:getTouchMovePosition())
                local cur_pos = cc.pAdd(cc.p(sender:getPosition()), cc.pSub(move_pos, sender.pre_pos))
                sender.pre_pos = move_pos
                sender:setPosition(cur_pos)
            ]]
        end
    end)

    AnimationRect:play(animation_rect)

    performWithDelay(animation_rect, function()
        local frameInfo = animation.animations[animation_rect.current_dir][animation_rect.current_act]
        local frameName = string.format(frameInfo.format, frameInfo.from)
        local sprtieFrame = display.getSpriteFrame(frameName)
        animation_rect:seekByName('AnimationNode'):setSpriteFrame(sprtieFrame)
        local rect = sprtieFrame:getRectInPixels()
        animation_rect:setContentSize(rect.width, rect.height)
        local centerPoint = animation_rect:getCenterPoint()
        
        local offset = sprtieFrame:getOffsetInPixels()
        centerPoint = cc.pSub(centerPoint, offset)
        animation_rect.anipos = centerPoint
        animation_rect:seekByName('AnimationNode'):setPosition(centerPoint)
        local center = cc.pAdd(display.center, offset)
        animation_rect:setPosition(center)
        animation_rect.center = center
        animation_rect.offset = offset

        -- 添加关闭按钮
        local btn_close = ccui.Text:create('X', CC_DESIGN.GAME_FONT, 16)
        btn_close:setOpacity(60)
        btn_close:setTextColor(cc.WHITE)
        btn_close:addClickEvent(function(sender, event)
            if self.curSelAniRect == animation_rect then
                self:resetSetting()
            end
            animation_rect:removeFromParent()
        end)
        local bpx = animation_rect:getWidth()-btn_close:getWidth()*0.5
        local bpy = animation_rect:getHeight()-btn_close:getHeight()*0.5
        btn_close:setPosition(bpx, bpy)
        btn_close:addTo(animation_rect, 2)
    end, 0.1)

    self:pushOneAniItem(item)
end

-- 移入动作
function EditorLayer:moveIn(itemIn)
    itemIn:stopAllActions()
    itemIn:runAction(
        cc.MoveTo:create(0.1, cc.p(0, self.Docker_Left_FixY))
    )
end

-- 移出动作
function EditorLayer:moveOut(itemOut)
    itemOut:stopAllActions()
    itemOut:runAction(
        cc.MoveTo:create(0.1, cc.p(-self.Docker_Left_FixX, self.Docker_Left_FixY))
    )
end

-- 显示当前帧数据
function EditorLayer:displayCurrentFrame(apply)
    if not self.curSelAniRect then return end

    local animation = self.curSelAniRect.animation
    local dirIndex, actIndex = self.curSelAniRect.current_dir, self.curSelAniRect.current_act
    local current_frame_info = animation:getActFrame(dirIndex, actIndex)

    -- 名称
    self.Text_Name_Value:setString(animation.name)
    
    -- 帧数
    self.Text_Num_Value:setString(current_frame_info.num)
    
    -- 帧率
    self.TextField_Rate:setString(current_frame_info.interval)
    
    -- 缩放
    self.TextField_Scale:setString(current_frame_info.scale)

    -- 偏移
    local offset = current_frame_info.offset
    local center = self.curSelAniRect.center
    self.Text_Offset_Value:setString(string.format('(%d,%d)', offset.x, offset.y))
    self.curSelAniRect:setPosition(center.x+offset.x, center.y+offset.y)

    -- 延迟
    self.TextField_Delay:setString(current_frame_info.delay)

    -- 透明
    self.TextField_Opacity:setString(current_frame_info.opacity)

    -- 方向
    self:selectDirItem(dirIndex, apply)

    -- 动作
    self:selectActItem(actIndex, apply)
    
    -- 混合源
    self.Text_Frame_Blend_Src:setVisible(current_frame_info.glblend)
    self.ListView_Blend_Src:setVisible(current_frame_info.glblend)
    if current_frame_info.glblend then
        self:selectBlendSrcItem(current_frame_info.glblend_src, apply)
    end
    
    -- 混合目
    self.Text_Frame_Blend_Dst:setVisible(current_frame_info.glblend)
    self.ListView_Blend_Dst:setVisible(current_frame_info.glblend)
    if current_frame_info.glblend then
        self:selectBlendDstItem(current_frame_info.glblend_dst, apply)
    end

    self:loadFrameListItems()
end

-- 载入设置
function EditorLayer:loadSetting()
    if not self.curSelAniRect then
        return
    end
    self.Docker_Setting:setVisible(true)
    self.ListView_Frame:setVisible(true)

    local animation = self.curSelAniRect.animation

    -- 方向
    self.ListView_Dir:removeAllItems()
    local dirNum = animation:getDirNum()
    for i=1, dirNum do
        local item = self.ListItem_Dir:clone()
        local dir = animation.dirs[i]
        item.dir = tostring(dir)
        item:seekByName('Text_Value'):setString(dir)
        self.ListView_Dir:pushBackCustomItem(item)
    end

    -- 动作
    self.ListView_Act:removeAllItems()
    local actNum = animation:getActNum(self.curSelAniRect.current_dir)
    for i=1, actNum do
        local item = self.ListItem_Act:clone()
        item.act = i
        item:seekByName('Text_Value'):setString(i)
        self.ListView_Act:pushBackCustomItem(item)
    end

    -- 混合源
    self.ListView_Blend_Src:removeAllItems()
    for i, glblend in ipairs(EditorConfig.BlendOptions) do
        local item = self.ListItem_Blend_Src:clone()
        item.glblend = glblend
        item:seekByName('Text_Value'):setString(glblend)
        self.ListView_Blend_Src:pushBackCustomItem(item)
    end

    -- 混合目
    self.ListView_Blend_Dst:removeAllItems()
    for i, glblend in ipairs(EditorConfig.BlendOptions) do
        local item = self.ListItem_Blend_Dst:clone()
        item.glblend = glblend
        item:seekByName('Text_Value'):setString(glblend)
        self.ListView_Blend_Dst:pushBackCustomItem(item)
    end

    -- 显示当前帧数据
    self:displayCurrentFrame(false)
end

-- 重置设置
function EditorLayer:resetSetting()
    if self.curSelAniRect then
        local aniName = self.curSelAniRect:getName()
        self:popOneAniItem(aniName)
    end

    self.curSelAniRect = nil
    self.Docker_Setting:setVisible(false)
    self.ListView_Frame:setVisible(false)
    self.ListView_Frame:stopAllActions()
    self.Text_Name_Value:setString('无')
    self.Text_Num_Value:setString('0')
    self.TextField_Rate:setString('0.1')
    self.TextField_Scale:setString('1.0')
    self.ListView_Dir:removeAllItems()
    self.ListView_Act:removeAllItems()
end

-- 撤销设置
function EditorLayer:discardSetting()
    if self.curSelAniRect then
        local dirIndex, actIndex = self.curSelAniRect.current_dir, self.curSelAniRect.current_act
        local actInfo = self.curSelAniRect.animation:discardActFrame(dirIndex, actIndex)
        self:modifyCurrentFrame({
            scale = actInfo.scale, 
            interval = actInfo.interval, 
            delay = actInfo.delay,
            opacity = actInfo.opacity,
        })
    end
end

-- 应用设置
function EditorLayer:applySetting()
    if self.curSelAniRect then
        local current_frame_info = self:getCurrentFrame()
        self.TextField_Rate:setString(current_frame_info.interval)
        self.TextField_Scale:setString(current_frame_info.scale)
        self.TextField_Delay:setString(current_frame_info.delay)
        local aniNode = self.curSelAniRect:seekByName('AnimationNode')
        aniNode:setScale(current_frame_info.scale)
        -- 新建动画
        AnimationRect:play(self.curSelAniRect)
        self.curSelAniRect:seekByName('AnimationNode'):setPosition(self.curSelAniRect.anipos)
    end
end

-- 保存设置
function EditorLayer:saveSetting()
    if self.curSelAniRect then
        self.curSelAniRect.animation:saveAllFrames()
        AnimationRect:save(self.curSelAniRect)
    end
end

return EditorLayer

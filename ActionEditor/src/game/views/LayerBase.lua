------------------------------------------------------
-- Name : UI层基类
-- Author : Reyn
-- Date : 2019.01.09
------------------------------------------------------

local LayerBase = class('LayerBase', function()
    return display.newLayer(cc.c4b(20,40,80,255))
end)

function LayerBase:ctor()
    self:enableNodeEvents()
    self:init()
    self:lazyInit()
    self:onNodeEvent()
end

function LayerBase:onNodeEvent()
	local function onEventHandler(eventType)
        if eventType == 'enter' then
            if self.onEnter then
                self:onEnter()
            end
            if self.initUI then
                self:initUI()
            end
            self:_onEnter()
        elseif eventType == 'exit' then
            self:_onExit(cname)
            if self.exitUI then
                self:exitUI()
            end
            if self.onExit then
                self:onExit()
            end
        elseif eventType == 'cleanup' then
            if self.onCleanup then
                self:onCleanup()
            end
        end
    end
    self:registerScriptHandler(onEventHandler)
end

local function initBaseNode(node)
    local desc = node:getDescription()
    if desc == 'Label' then
        node:setFontName(CC_DESIGN.GAME_FONT)
    end
    if desc == 'ListView' then
        node:setScrollBarEnabled(false)
    end
    local children = node:getChildren()
    for _, v in ipairs(children) do
        initBaseNode(v)
    end
end

function LayerBase:lazyInit()
    if self.csbName then
        local csbPath  = string.format('csb/%s.csb', self.csbName)
        local csbNode = cc.CSLoader:createNode(csbPath)
        csbNode:setName('CsbNode')
        csbNode:addTo(self)
        initBaseNode(csbNode)
        self.csbNode = csbNode
    end

    if self.bgColor then
        self:setColor(self.bgColor)
    end
end

function LayerBase:_onEnter()
    print(self.__cname .. ' onEnter')
end

function LayerBase:_onExit()
    print(self.__cname .. ' onExit')
end

return LayerBase

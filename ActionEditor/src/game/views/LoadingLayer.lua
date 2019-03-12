------------------------------------------------------
-- Name : Loading层
-- Author : Reyn
-- Date : 2019.01.09
------------------------------------------------------

local LoadingLayer = class('LoadingLayer', require('game.views.LayerBase'))
local EditorLoadItems = require('game.config.EditorLoadItems')

function LoadingLayer:init()
    self.csbName = 'LoadingLayer'
end

function LoadingLayer:onEnter()
    self:initUI()
end

function LoadingLayer:initUI()
    self.Docker_Options = self.csbNode:seekByName('Docker_Options')
    self.Text_Export    = self.Docker_Options:seekByName('Text_Export')
    self.Text_Edit      = self.Docker_Options:seekByName('Text_Edit')
    self.LoadingBg      = self.csbNode:seekByName('LoadingBg')
    self.LoadingText    = self.LoadingBg:seekByName('LoadingText')
    self.LoadingBar     = self.LoadingBg:seekByName('LoadingBar')
    self.LoadingText:setString('正在加载资源')
    self.LoadingBg:setVisible(false)
    self.Text_Export:addClickEvent(function(sender, event)
        sender:setTouchOnce(1)
        exportAllAnimations()
    end)
    self.Text_Edit:addClickEvent(function(sender, event)
        sender:setTouchOnce(1)
        self.LoadingBg:setVisible(true)
        self.Docker_Options:setVisible(false)
        self:loadResources()
    end)
end

function LoadingLayer:loadResources() 
    self.current_index = 0
    self.total_percent = 0
    self.total_texture = {}
    for key, item in pairs(EditorLoadItems) do
        if key ~= 'Other' then
            self.total_percent = self.total_percent + #item
            for i, t in ipairs(item) do
                local texture = require('game.const.' .. key .. '.' .. t)['texture']
                texture = string.gsub(texture, 'plist', '')
                table.insert(self.total_texture, texture)
            end
        end
    end

    self.isLoaded = false
    self:onUpdate(handler(self, self.onOneLoaded))
end

function LoadingLayer:onOneLoaded(dt)
    if self.isLoaded then return end

    self.current_index = self.current_index + 1
    if self.current_index > self.total_percent then
        self.isLoaded = true
        self:unscheduleUpdate()
        self:onLoaded()
        return
    end
    local plistFile = self.total_texture[self.current_index] .. 'plist'
    self.LoadingText:setString(string.format('正在加载资源(%s)', plistFile))
    self.LoadingBar:setContentSize(cc.size(1000*self.current_index/self.total_percent, 50))
    display.addSpriteFrames(plistFile)
end

function LoadingLayer:onLoaded()
    self.LoadingText:setString('资源加载完成')

    local EditorLayer = require('game.views.EditorLayer'):create()
    EditorScene:addChild(EditorLayer)

    self:setVisible(false)
    performWithDelay(self, function()
        self:removeSelf()
    end, 1)
end

return LoadingLayer

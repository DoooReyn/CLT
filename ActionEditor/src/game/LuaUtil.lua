cc.exports.EditorConfig = require('game.config.EditorConfig')
cc.exports.AnimationMap = require('game.config.AnimationMap')
cc.exports.EditorLoadItems = require('game.config.EditorLoadItems')
cc.exports.AnimationHelper = require('game.AnimationHelper')
cc.exports.AnimationRect = require('game.AnimationRect')

local function exportstring( s )
	return string.format("%q", s)
end

cc.exports.serialize = function(obj)  
    local lua = ""  
    local t = type(obj)  
    if t == "number" then  
        lua = lua .. obj  
    elseif t == "boolean" then  
        lua = lua .. tostring(obj)  
    elseif t == "string" then  
        lua = lua .. string.format("%q", obj)  
    elseif t == "table" then  
        lua = lua .. "{\n"  
    for k, v in pairs(obj) do  
        lua = lua .. "[" .. serialize(k) .. "]=" .. serialize(v) .. ",\n"  
    end  
    local metatable = getmetatable(obj)  
        if metatable ~= nil and type(metatable.__index) == "table" then  
        for k, v in pairs(metatable.__index) do  
            lua = lua .. "[" .. serialize(k) .. "]=" .. serialize(v) .. ",\n"  
        end  
    end  
        lua = lua .. "}"  
    elseif t == "nil" then  
        return nil  
    else  
        error("can not serialize a " .. t .. " type.")  
    end  
    return lua  
end  
  
cc.exports.unserialize = function (lua)  
    local t = type(lua)  
    if t == "nil" or lua == "" then  
        return nil  
    elseif t == "number" or t == "string" or t == "boolean" then  
        lua = tostring(lua)  
    else  
        error("can not unserialize a " .. t .. " type.")  
    end  
    lua = "return " .. lua  
    local func = loadstring(lua)  
    if func == nil then  
        return nil  
    end  
    return func()  
end  


function table.save(  tbl, filename )
	local charS,charE = "   ","\n"
	local file,err = io.open( filename, "wb" )
	if err then 
		printError(err)
		return err 
	end
	file:write('return ')
	file:write(serialize(tbl))
	file:close()
end

--------------------------------------------光标(head)----------------------------------------
--设置输入框光标  
-- textField:输入控件
-- isEnabled:是否一开始就显示光标
-- isCenter:是否中心对齐
-- callFunc:回调
cc.exports.setCursorField = function(textField, isEnabled, isCenter, callFunc)
	textField:setFontName(CC_DESIGN.GAME_FONT)
	--初始化设置
    local inputBtn = textField:getChildByName('CURSOR')
    if inputBtn then
		inputBtn:setVisible(isEnabled)
        return inputBtn
    end
    if isCenter then
        textField:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    end

    --初始化光标
    local fontSize = textField:getFontSize()
    local cursor = ccui.Text:create('|', CC_DESIGN.GAME_FONT, fontSize)
    cursor:setName('CURSOR')
	cursor:setVisible(isEnabled)
    local fadeOut = cc.FadeOut:create(0.5)
    local fadeIn = cc.FadeIn:create(0.5)
    cursor:runAction(cc.RepeatForever:create(cc.Sequence:create(fadeOut,fadeIn)))
    setCursorPos(cursor, textField, isCenter)
	textField:add(cursor)
	
    --事件监听
    local function textFieldEvent(sender, eventType)
        if eventType == ccui.TextFiledEventType.attach_with_ime then
            cursor:setVisible(true)
            setCursorPos(cursor, textField, isCenter)
        elseif eventType == ccui.TextFiledEventType.detach_with_ime then
            cursor:setVisible(false)
        elseif eventType == ccui.TextFiledEventType.insert_text then
            setCursorPos(cursor, textField, isCenter)
        elseif eventType == ccui.TextFiledEventType.delete_backward then
            setCursorPos(cursor, textField, isCenter)
        end

        if callFunc then
            callFunc(sender, eventType)
        end
    end
    textField:addEventListener(textFieldEvent)

    return cursor
end

--设置光标位置
cc.exports.setCursorPos = function(cursor, textField, isCenter)
    local fontSize = textField:getFontSize()
    local function getInputLen(isCenter)
        local str = textField:getString()
		local text = ccui.Text:create(str, CC_DESIGN.GAME_FONT, fontSize)
		local width = text:getWidth()
        if isCenter then
            width = (textField:getWidth()+width)*0.5
		end
		if width > 0 then
			width = width + 2
		end
        return width
    end
    cursor:onUpdate(function()
        cursor:setPosition(getInputLen(isCenter), fontSize*0.5)
    end)
end

-- 导出所有动画
cc.exports.exportAllAnimations = function()
    for dir, items in pairs(EditorLoadItems) do
        for index, item in ipairs(items) do
            if dir ~= 'Other' then
                local file = string.format('game.const.%s.%s', dir, item)
                local animation = AnimationHelper:createWithFile(file)
                if animation then
                    AnimationMap[animation.realname] = animation.animations
                end
            end
        end
    end
    table.save(AnimationMap, EditorConfig.AnimationMapFile)
    Game:PushInfoTip('配置导出完成！')
end

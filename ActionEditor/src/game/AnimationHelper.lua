------------------------------------------------------
-- Name : 帧动画辅助工具
-- Author : Reyn
-- Date : 2019.01.11
------------------------------------------------------

local AnimationHelper = {}
AnimationHelper.__index = AnimationHelper

local AnimationTemplate = {
    flip        = false, 
    delay       = 0,
    scale       = 1.0, 
    offset      = cc.p(0,0), 
    opacity     = 255,
    interval    = 0.1, 
    glblend     = true, 
    glblend_src = 1, 
    glblend_dst = 771, 
}
local AnimationTag = 12321

-- 使用文件创建帧动画
function AnimationHelper:createWithFile(filepath)
    local frames = require(filepath)
    if not frames then
        Game:PushWarnTip(string.format('%s的帧动画配置%s不存在', item, file))
        return nil
    end
    return AnimationHelper:createWithFrames(frames)
end

-- 使用帧数据创建帧动画
function AnimationHelper:createWithFrames(framesInfo)
    local animation = clone(framesInfo)
    local name_arr = string.split(string.split(animation.texture, '.')[1], '/')
    animation.realname = name_arr[#name_arr]
    animation.name = string.split(animation.format, '_')[1]
    animation.dirs = table.keys(animation.frames)
    table.sort(animation.dirs, function(a, b)
        return tonumber(a) < tonumber(b)
    end)

    -- 缓存所有动画数据
    animation.animations = {}
    for dirIndex, dirInfo in pairs(animation.frames) do
        animation.animations[dirIndex] = {}
        for actIndex, actInfo in ipairs(dirInfo) do
            local args = AnimationHelper:getAniActFrame(animation.realname, dirIndex, actIndex)
            animation.animations[dirIndex][actIndex] = {
                format      = animation.format, 
                from        = actInfo[1], 
                num         = actInfo[2], 
                opacity	    = args.opacity or AnimationTemplate.opacity,
                offset      = args.offset or AnimationTemplate.offset,
                delay       = args.delay or AnimationTemplate.delay,
                interval    = args.interval or AnimationTemplate.interval,
                flip        = args.flip or AnimationTemplate.flip,
                scale       = args.scale or AnimationTemplate.scale,
                glblend     = args.glblend or AnimationTemplate.glblend,
                glblend_src = args.glblend_src or AnimationTemplate.glblend_src,
                glblend_dst = args.glblend_dst or AnimationTemplate.glblend_dst,
            }
        end
    end

    -- 临时所有动画数据
    animation.animations_temp = clone(animation.animations)

    -- 获得方向上的帧数据
    function animation:getDirFrames(dirIndex)
        return animation.frames[tostring(dirIndex)]
    end

    -- 获得方向数量
    function animation:getDirNum()
        return #animation.dirs
    end

    -- 获得方向上的动作数量
    function animation:getActNum(dirIndex)
        local frame_dir = animation:getDirFrames(dirIndex)
        if frame_dir then
            return #frame_dir
        end
        return 0
    end

    -- 获得方向上的动作帧数据
    function animation:getActFrame(dirIndex, actIndex)
        local frame_dir = animation.animations_temp[dirIndex]
        if not frame_dir then return nil end
        return animation.animations_temp[dirIndex][actIndex]
    end

    -- 设置方向上的动作帧数据
    function animation:setActFrame(dirIndex, actIndex, frameInfo)
        local frame_dir = animation.animations_temp[dirIndex]
        if not frame_dir then return end
        animation.animations_temp[dirIndex][actIndex] = clone(frameInfo)
    end

    -- 还原方向上的动作帧数据
    function animation:discardActFrame(dirIndex, actIndex)
        local frame_dir_temp = animation.animations_temp[dirIndex]
        local frame_dir_real = animation.animations[dirIndex]
        if not frame_dir_temp then return end
        if not frame_dir_real then return end
        local actInfo = animation.animations[dirIndex][actIndex]
        animation.animations_temp[dirIndex][actIndex] = actInfo
        return actInfo
    end

    -- 保存方向上的动作帧数据
    function animation:saveActFrame(dirIndex, actIndex)
        local frame_dir_temp = animation.animations_temp[dirIndex]
        local frame_dir_real = animation.animations[dirIndex]
        if not frame_dir_temp then return end
        if not frame_dir_real then return end
        local actInfo = animation.animations_temp[dirIndex][actIndex]
        animation.animations[dirIndex][actIndex] = actInfo
        return actInfo
    end

    -- 还原所有帧数据
    function animation:discardAllFrames()
        animation.animations_temp = clone(animation.animations)
    end

    -- 保存所有帧数据
    function animation:saveAllFrames()
        animation.animations = clone(animation.animations_temp)
    end

    -- 创建动画
    function animation:newAni(dirIndex, actIndex, aniTime)
        local dirInfo = animation.animations_temp[dirIndex]
        if not dirInfo then return nil end
        local actInfo = dirInfo[actIndex]
        if not actInfo then return nil end
        actInfo.interval = aniTime or actInfo.interval
        local animate, aniNode = display.newAnimation(actInfo.format, actInfo.from, actInfo.num, actInfo.interval)
        if actInfo.glblend then
            aniNode:setBlendFunc({src = actInfo.glblend_src, dst = actInfo.glblend_dst})
        end
        aniNode:setScale(actInfo.scale)
        aniNode:setFlippedX(actInfo.flip)
        aniNode:setOpacity(actInfo.opacity)

        local aniAct = cc.Animate:create(animate)
        function aniNode:play(times)
            times = times or 1
            local dltAct = cc.DelayTime:create(actInfo.delay)
            local animation = cc.Repeat:create(cc.Sequence:create(dltAct, aniAct), times)
            animation:setTag(AnimationTag)
            aniNode:runAction( animation )
        end
        function aniNode:playForever()
            local dltAct = cc.DelayTime:create(actInfo.delay)
            local animation = cc.RepeatForever:create(cc.Sequence:create(dltAct, aniAct))
            animation:setTag(AnimationTag)
            aniNode:runAction(animation)
        end
        function aniNode:stop(tag)
            tag = tag or AnimationTag
            aniNode:stopActionByTag(tag)
        end
        animation.aniNode = aniNode
        return aniAct, aniNode
    end

    return animation
end

function AnimationHelper:getAniFrames(aniName)
    return AnimationMap[aniName]
end

function AnimationHelper:setAniFrames(aniName, frames)
    AnimationMap[aniName] = clone(frames)
end

function AnimationHelper:getAniActFrame(aniName, dirIndex, actIndex)
    local default = clone(AnimationTemplate)
    local aniFrames = AnimationMap[aniName]
    if not aniFrames then return default end
    local dirInfo = aniFrames[dirIndex]
    if not dirInfo then return default end
    return dirInfo[actIndex] or default
end

function AnimationHelper:setAniActFrame(aniName, dirIndex, actIndex, args)
    local aniFrames = AnimationMap[aniName]
    if not aniFrames then 
        AnimationMap[aniName] = {}
    end
    if not AnimationMap[aniName][dirIndex] then
        AnimationMap[aniName][dirIndex] = {}
    end
    AnimationMap[dirIndex][actIndex] = clone(args)
end

return AnimationHelper
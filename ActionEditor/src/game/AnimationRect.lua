------------------------------------------------------
-- Name : 动画矩形区
-- Author : Reyn
-- Date : 2019.01.17
------------------------------------------------------

local AnimationRect = {}

-- 播放动画节点
function AnimationRect:play(animation_rect)
    if not animation_rect then return end
    animation_rect:removeNode('AnimationNode')
    local dirIndex = animation_rect.current_dir
    local actIndex = animation_rect.current_act
    local aniAct, aniNode = animation_rect.animation:newAni(dirIndex, actIndex)
    if aniAct and aniNode then
        aniNode:playForever()
        aniNode:setName('AnimationNode')
        aniNode:setPosition(animation_rect:getCenterPoint())
        aniNode:addTo(animation_rect)
        Game:PushInfoTip(string.format('正在播放%s动画', animation_rect:getName()))
    else
        Game:PushWarnTip(string.format('%s动画播放失败', animation_rect:getName()))
    end
    AnimationRect:blend(animation_rect)
end

-- 暂停动画节点
function AnimationRect:pause(animation_rect)
    if not animation_rect then return end
    local aniNode = animation_rect:seekByName('AnimationNode')
    if not aniNode then return end
    aniNode:stopAllActions()
    Game:PushInfoTip(string.format('动画%s已暂停', animation_rect:getName()))
end

-- 保存动画节点
function AnimationRect:save(animation_rect)
    if not animation_rect then return end
    local animation = animation_rect.animation
    AnimationMap[animation.realname] = animation.animations
    table.save(AnimationMap, EditorConfig.AnimationMapFile)
    Game:PushInfoTip(string.format('动画%s已保存', animation.realname))
end

-- 翻转动画节点
function AnimationRect:flip(animation_rect)
    if not animation_rect then return end
    local aniNode = animation_rect:seekByName('AnimationNode')
    if not aniNode then return end
    aniNode:setFlippedX(not aniNode:isFlippedX())
end

-- 混合动画节点
function AnimationRect:blend(animation_rect)
    if not animation_rect then return end
    local aniNode = animation_rect:seekByName('AnimationNode')
    if not aniNode then return end
    local aniName, dirIndex, actIndex = animation_rect.name, animation_rect.current_dir, animation_rect.current_act
    local current_frame_info = animation_rect.animation:getActFrame(animation_rect.current_dir, animation_rect.current_act)
    if current_frame_info.glblend then
        aniNode:setBlendFunc({src = current_frame_info.glblend_src, dst = current_frame_info.glblend_dst}) 
    else
        aniNode:setBlendFunc({src = 1, dst = 771})
    end
end

return AnimationRect
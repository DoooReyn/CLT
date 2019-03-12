local EditorConfig = {
    -- 支持的动画选项
    LoadItemList = {
        {name = '动画', dir = 'Effect'},
        {name = '技能', dir = 'Skill'},
        {name = '角色', dir = 'Role'},
        {name = '武器', dir = 'Weapon'},
        {name = '坐骑', dir = 'Mount'},
        {name = '骑影', dir = 'ShadowOfMount'},
        {name = '怪物', dir = 'Monster'},
        {name = '怪影', dir = 'ShadowOfMonster'},
        {name = 'NPC',  dir = 'Npc'},
        {name = 'N影',  dir = 'ShadowOfNpc'},
        {name = '创角', dir = 'RoleDisplayModel'},
    },

    -- 方向、动作子项文本颜色（正常、选中）
    GetListItemColor = function(isSelected)
        return isSelected and cc.c3b(245, 100, 100) or cc.c3b(220, 200, 100)
    end,

    -- 可更换的地图
    Map = {
        BlockWidth = 512,
        BlockHeight = 512,
        GetBlock = function(mapId, row, col)
            local filepath = string.format('Map/Block/%d/%d0%02d', mapId, row, col)
            local jpgPath = filepath .. '.jpg'
            if cc.FileUtils:getInstance():isFileExist(jpgPath) then
                return jpgPath
            end
            return filepath .. '.png'
        end,
        Blocks = {
            {1,11,15},
            {2,14,17},
        }
    },

    -- 混合可选项
    BlendOptions = {
        0,
        1,
        0x0300,
        0x0301,
        0x0302,
        0x0303,
        0x0304,
        0x0305,
        0x0306,
        0x0307,
        0x0308,
    },

    -- 动画参数配置文件
    AnimationMapFile = '../../src/game/config/AnimationMap.lua'
}

return EditorConfig
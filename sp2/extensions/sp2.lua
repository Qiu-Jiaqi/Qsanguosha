extension = sgs.Package("sp2", sgs.Package_GeneralPack)
-- bug：影箭发动会播放两次台词。还不知道为何，试过改变使用技能卡的地方，还是不行
-- 孙茹
sunru = sgs.General(extension, "sunru", "wu", "3", false, true)
-- 影箭：准备阶段开始时，你可以视为使用一张无距离限制的【杀】。
-- 技能卡
yingjianCard =
    sgs.CreateSkillCard {
    name = "yingjian",
    -- filtet：默认为一名“其他玩家”
    filter = function(self, targets, to_select, Self)
        if #targets == 0 then
            -- false 表示无视距离限制
            if sgs.Self:canSlash(to_select, false) then
                return true
            end
        end
        return false
    end,
    -- feasible：默认为target_fixed == true或选择了至少一名玩家为目标，此处可不写的
    feasible = function(self, targets, Self)
        return #targets == 1
    end,
    on_use = function(self, room, source, targets)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName("_" .. self:objectName())
        room:useCard(sgs.CardUseStruct(slash, source, targets[1]))
    end
    -- 使用tag存储数据
    -- on_use = function(self, room, source, targets)
    --     local target = sgs.QVariant()
    --     target:setValue(targets[1])
    --     room:setTag(self:objectName(), target)
    -- end
}
-- 视为技
yingjianVS =
    sgs.CreateZeroCardViewAsSkill {
    name = "yingjian",
    response_pattern = "@@yingjian",
    view_as = function(self)
        return yingjianCard:clone()
    end
}
-- 触发技
yingjian =
    sgs.CreateTriggerSkill {
    name = "yingjian",
    events = {sgs.EventPhaseStart},
    view_as_skill = yingjianVS,
    can_trigger = function(self, event, room, player, data)
        if
            player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start and
                sgs.Slash_IsAvailable(player)
         then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        return room:askForUseCard(player, "@@yingjian", "@yingjian_invoke")
    end
    -- 使用tag获取存储的数据
    -- on_effect = function(self, event, room, player, data, ask_who)
    --     local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    --     slash:setSkillName("_" .. self:objectName())
    --     room:useCard(sgs.CardUseStruct(slash, player, room:getTag(self:objectName()):toPlayer()), false)
    --     room:removeTag(self:objectName())
    --     return false
    -- end
}
-- 触发技
-- 使用CreatePhaseChangeSkill创建阶段转换触发技，events不用写，但on_phasechange必须重写
-- yingjian =
--     sgs.CreatePhaseChangeSkill {
--     name = "yingjian",
--     view_as_skill = yingjianVS,
--     can_trigger = function(self, event, room, player, data)
--         if
--             player and player:isAlive() and player:hasSkill(self:objectName()) and
--                 player:getPhase() == sgs.Player_Start and
--                 sgs.Slash_IsAvailable(player)
--          then
--             return self:objectName()
--         end
--         return ""
--     end,
--     on_cost = function(self, event, room, player, data, ask_who)
--         return room:askForUseCard(player, "@@yingjian", "@yingjian_invoke")
--     end,
--     on_phasechange = function(self, player)
--         return false
--     end
-- }
-- 目标修改技，也可以不要啦,直接在技能卡里判断就好
-- yingjianMod =
--     sgs.CreateTargetModSkill {
--     name = "#yingjian-slash",
--     distance_limit_func = function(self, player, card)
--         return card:getSkillName() == "yingjian" and 1000 or 0
--     end
-- }

-- 释衅：锁定技，每当你受到火焰伤害时，防止此伤害。
shixin =
    sgs.CreateTriggerSkill {
    name = "shixin",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageInflicted},
    can_trigger = function(self, event, room, player, data)
        if
            player and player:isAlive() and player:hasSkill(self:objectName()) and
                data:toDamage().nature == sgs.DamageStruct_Fire
         then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data) then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true)
            room:broadcastSkillInvoke(self:objectName())
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        local msg = sgs.LogMessage()
        msg.type = "#shixinProtect"
        msg.from = player
        msg.arg = data:toDamage().damage
        msg.arg2 = "fire_nature"
        room:sendLog(msg)
        return true
    end
}
sunru:addSkill(yingjian)
-- sunru:addSkill(yingjianMod)
sunru:addSkill(shixin)
sgs.LoadTranslationTable {
    ["stars"] = "sp2",
    ["sunru"] = "孙茹",
    ["&sunru"] = "孙茹",
    ["#sunru"] = "出水青莲",
    ["~sunru"] = "佑我江东，虽死无怨。",
    ["yingjian"] = "影箭",
    [":yingjian"] = "准备阶段开始时，你可以视为使用一张无距离限制的【杀】。",
    ["@yingjian_invoke"] = "你可以发动“影箭”，视为使用一张无距离限制的【杀】",
    ["$yingjian1"] = "翩翩一云端，仿若桃花仙。",
    ["$yingjian2"] = "没牌，又有何不可能的？",
    ["shixin"] = "释衅",
    [":shixin"] = "锁定技，每当你受到火焰伤害时，防止此伤害。",
    ["$shixin1"] = "释怀之戾气，化君之不悦。",
    ["$shixin2"] = "薪薪之火，安能伤我？",
    ["#shixinProtect"] = "%from防止了%arg点%arg2伤害。"
}
return {extension}

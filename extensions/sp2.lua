sp2 = sgs.Package("sp2", sgs.Package_GeneralPack)
sgs.LoadTranslationTable {
    ["sp2"] = "sp2"
}
-- 孙茹
sunru = sgs.General(sp2, "sunru", "wu", "3", false, true)
-- 珠联璧合：陆逊
sunru:addCompanion("luxun")
-- 影箭：准备阶段开始时，你可以视为使用一张无距离限制的【杀】。
yingjian_card =
    sgs.CreateSkillCard {
    name = "yingjian",
    mute = true, -- 添加mute参数，关闭自动播放技能配音，重复播放技能配音问题解决
    filter = function(self, targets, to_select, Self)
        -- canSlash中的false表示无视距离限制
        return #targets == 0 and sgs.Self:canSlash(to_select, false)
    end,
    on_use = function(self, room, source, targets)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName("_" .. self:objectName())
        room:useCard(sgs.CardUseStruct(slash, source, targets[1]))
    end
}
yingjian_vs =
    sgs.CreateZeroCardViewAsSkill {
    name = "yingjian",
    response_pattern = "@@yingjian",
    view_as = function(self)
        return yingjian_card:clone()
    end
}
yingjian =
    sgs.CreateTriggerSkill {
    name = "yingjian",
    events = sgs.EventPhaseStart,
    view_as_skill = yingjian_vs,
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
        return room:askForUseCard(player, "@@yingjian", "#yingjian_invoke")
    end
}
-- 释衅：锁定技，每当你受到火焰伤害时，防止此伤害。
shixin =
    sgs.CreateTriggerSkill {
    name = "shixin",
    frequency = sgs.Skill_Compulsory,
    events = sgs.DamageInflicted,
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
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data)
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        room:sendCompulsoryTriggerLog(player, self:objectName(), true)
        room:broadcastSkillInvoke(self:objectName())
        local msg = sgs.LogMessage()
        msg.type = "$shixin_protect"
        msg.from = player
        msg.arg = data:toDamage().damage
        msg.arg2 = "fire_nature"
        room:sendLog(msg)
        return true
    end
}
sunru:addSkill(yingjian)
sunru:addSkill(shixin)
sgs.LoadTranslationTable {
    ["sunru"] = "孙茹",
    ["&sunru"] = "孙茹",
    ["#sunru"] = "出水青莲",
    ["~sunru"] = "佑我江东，虽死无怨。",
    ["yingjian"] = "影箭",
    [":yingjian"] = "准备阶段开始时，你可以视为使用一张无距离限制的【杀】。",
    ["$yingjian1"] = "翩翩一云端，仿若桃花仙。",
    ["$yingjian2"] = "没牌，又有何不可能的？",
    ["#yingjian_invoke"] = "你可以发动“影箭”，视为使用一张无距离限制的【杀】。",
    ["shixin"] = "释衅",
    [":shixin"] = "锁定技，每当你受到火焰伤害时，防止此伤害。",
    ["$shixin1"] = "释怀之戾气，化君之不悦。",
    ["$shixin2"] = "薪薪之火，安能伤我？",
    ["$shixin_protect"] = "%from 防止了 %arg 点 %arg2 伤害"
}
return {sp2}

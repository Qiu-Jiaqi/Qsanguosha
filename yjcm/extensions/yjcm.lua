extension = sgs.Package("yjcm", sgs.Package_GeneralPack)
-- 张春华
zhangchunhua = sgs.General(extension, "zhangchunhua", "wei", "3", false, true)
-- 绝情：锁定技，你即将造成或受到的伤害均视为失去体力，此时若你手牌不为空，需弃置一张手牌。
jueqing =
    sgs.CreateTriggerSkill {
    name = "jueqing",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Predamage, sgs.DamageForseen},
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName()) then
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
        if not player:isKongcheng() then
            room:askForDiscard(player, self:objectName(), 1, 1, true, false)
        end
        room:loseHp(data:toDamage().to, data:toDamage().damage)
        -- 取消原效果，改为体力流失，返回true
        return true
    end
}
-- 伤逝：当你的手牌数小于X时，你可以将手牌摸至X张。（X为你已损失的体力值）
shangshi =
    sgs.CreateTriggerSkill {
    name = "shangshi",
    events = {
        sgs.EventPhaseChanging,
        sgs.CardsMoveOneTime,
        sgs.MaxHpChanged,
        sgs.HpChanged
    },
    can_trigger = function(self, event, room, player, data)
        if
            player and player:isAlive() and player:hasSkill(self:objectName()) and
                player:getHandcardNum() < player:getLostHp()
         then
            return self:objectName()
        end
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        if player:askForSkillInvoke(self:objectName()) then
            room:broadcastSkillInvoke(self:objectName())
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        player:drawCards(player:getLostHp() - player:getHandcardNum(), self:objectName())
        return false
    end
}
zhangchunhua:addSkill(jueqing)
zhangchunhua:addSkill(shangshi)
sgs.LoadTranslationTable {
    ["yjcm"] = "一将成名",
    ["zhangchunhua"] = "张春华",
    ["&zhangchunhua"] = "张春华",
    ["#zhangchunhua"] = "冷血皇后",
    ["~zhangchunhua"] = "今夕何夕，君已陌路。",
    ["jueqing"] = "绝情",
    [":jueqing"] = "锁定技，你即将造成或受到的伤害均视为失去体力，此时若你手牌不为空，需弃置一张手牌。",
    ["$jueqing1"] = "化爱为恨，恨之透骨。",
    ["$jueqing2"] = "为上位者，当至无情。",
    ["shangshi"] = "伤逝",
    [":shangshi"] = "当你的手牌数小于X时，你可以将手牌摸至X张。（X为你已损失的体力值）",
    ["$shangshi1"] = "身伤易愈，心伤难合。",
    ["$shangshi2"] = "心随情碎，情随伤逝。"
}
return {extension}

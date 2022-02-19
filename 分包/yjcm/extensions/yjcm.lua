yjcm = sgs.Package("yjcm", sgs.Package_GeneralPack)
sgs.LoadTranslationTable {
    ["yjcm"] = "一将成名"
}
-- 张春华
zhangchunhua = sgs.General(yjcm, "zhangchunhua", "wei", "3", false, true)
-- 珠联璧合：司马懿
zhangchunhua:addCompanion("simayi")
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
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data)
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        room:sendCompulsoryTriggerLog(player, self:objectName(), true)
        room:broadcastSkillInvoke(self:objectName())
        if not player:isKongcheng() then
            -- 弃置者，原因，弃牌数，最小数，[是否可取消=false，是否包括装备=false，提示语=null，是否显示技能发动效果=false]
            room:askForDiscard(player, self:objectName(), 1, 1, false, false, nil, true)
        end
        room:loseHp(data:toDamage().to, data:toDamage().damage)
        -- 取消原效果，改为体力流失，返回true
        return true
    end
}
-- 伤逝：当你的手牌数小于X时，你可以将手牌摸至X张。（X为你已损失的体力值的两倍）
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
                player:getHandcardNum() < player:getLostHp() * 2
         then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        return player:askForSkillInvoke(self:objectName())
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        room:broadcastSkillInvoke(self:objectName())
        room:drawCards(player, player:getLostHp() * 2 - player:getHandcardNum(), self:objectName())
        return false
    end
}
zhangchunhua:addSkill(jueqing)
zhangchunhua:addSkill(shangshi)
sgs.LoadTranslationTable {
    ["zhangchunhua"] = "张春华",
    ["&zhangchunhua"] = "张春华",
    ["#zhangchunhua"] = "冷血皇后",
    ["~zhangchunhua"] = "今夕何夕，君已陌路。",
    ["jueqing"] = "绝情",
    [":jueqing"] = "锁定技，你即将造成或受到的伤害均视为失去体力，此时若你手牌不为空，需弃置一张手牌。",
    ["$jueqing1"] = "化爱为恨，恨之透骨。",
    ["$jueqing2"] = "为上位者，当至无情。",
    ["shangshi"] = "伤逝",
    [":shangshi"] = "当你的手牌数小于X时，你可以将手牌摸至X张。（X为你已损失的体力值的两倍）",
    ["$shangshi1"] = "身伤易愈，心伤难合。",
    ["$shangshi2"] = "心随情碎，情随伤逝。"
}
return {yjcm}

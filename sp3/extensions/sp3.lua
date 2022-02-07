sp3 = sgs.Package("sp3", sgs.Package_GeneralPack)
sgs.LoadTranslationTable {
    ["sp3"] = "sp3"
}
-- 马云禄
mayunlu = sgs.General(sp3, "mayunlu", "shu", "4", false, true)
-- 珠联璧合：马超、赵云
mayunlu:addCompanion("machao")
mayunlu:addCompanion("zhaoyun")
-- 马术：锁定技，你与其他角色距离-1。
mashu_mayunlu =
    sgs.CreateDistanceSkill {
    name = "mashu_mayunlu",
    correct_func = function(self, from, to)
        return from:hasShownSkill(self:objectName()) and -1 or 0
    end
}
-- 凤魄：当你使用【杀】或【决斗】仅指定一名角色为目标后，你可以观看其手牌然后选择一项：1.摸X张牌；2.你使用此牌造成的伤害+X。
--      （X为其方块手牌数，若你本局游戏内杀死过角色，则修改为其红色手牌数）
fengpo =
    sgs.CreateTriggerSkill {
    name = "fengpo",
    events = {sgs.TargetConfirmed, sgs.ConfirmDamage, sgs.BuryVictim},
    on_record = function(self, event, room, player, data)
        local mayunlu = room:findPlayerBySkillName(self:objectName())
        if mayunlu and mayunlu:isAlive() and mayunlu:hasShownSkill(self:objectName()) then
            if event == sgs.ConfirmDamage and player:getMark("fengpo_addDamage") > 0 then
                -- 加伤害时计算伤害
                room:sendCompulsoryTriggerLog(mayunlu, self:objectName(), true)
                local damage = data:toDamage()
                local msg = sgs.LogMessage()
                msg.type = "$fengpo_addDamage"
                msg.from = mayunlu
                msg.arg = self:objectName()
                msg.card_str = damage.card:toString()
                msg.arg2 = "+" .. player:getMark("fengpo_addDamage")
                room:sendLog(msg)
                damage.damage = damage.damage + player:getMark("fengpo_addDamage")
                player:setMark("fengpo_addDamage", 0)
                data:setValue(damage)
            elseif
                event == sgs.BuryVictim and data:toDeath().damage.from == mayunlu and
                    mayunlu:getMark("fengpo_upgrade") == 0
             then
                -- 游戏内第一次杀角色时加标记
                room:sendCompulsoryTriggerLog(mayunlu, self:objectName(), true)
                mayunlu:addMark("fengpo_upgrade")
                local msg = sgs.LogMessage()
                msg.type = "$fengpo_upgrade"
                msg.from = mayunlu
                msg.to:append(player)
                msg.arg = self:objectName()
                room:sendLog(msg)
            end
        end
    end,
    can_trigger = function(self, event, room, player, data)
        if
            event == sgs.TargetConfirmed and player and player:isAlive() and player:hasSkill(self:objectName()) and
                data:toCardUse().from == player and
                data:toCardUse().to:length() == 1 and
                (data:toCardUse().card:isKindOf("Slash") or data:toCardUse().card:isKindOf("Duel"))
         then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        return player:askForSkillInvoke(self:objectName(), data)
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        room:broadcastSkillInvoke(self:objectName())
        local target = data:toCardUse().to:at(0)
        room:showAllCards(target, player)
        local choices = {"draw", "addDamage"}
        local x = 0
        if player:getMark("fengpo_upgrade") == 0 then
            for _, card in sgs.qlist(target:getHandcards()) do
                if card:getSuit() == sgs.Card_Diamond then
                    x = x + 1
                end
            end
        else
            for _, card in sgs.qlist(target:getHandcards()) do
                if card:isRed() then
                    x = x + 1
                end
            end
        end
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
        if choice == "draw" then
            room:drawCards(player, x, self:objectName())
        elseif choice == "addDamage" then
            -- 存数字的话，直接用mark好了，存其它再用tag
            player:setMark("fengpo_addDamage", x)
        end
        return false
    end
}
mayunlu:addSkill(mashu_mayunlu)
mayunlu:addSkill(fengpo)
sgs.LoadTranslationTable {
    ["mayunlu"] = "马云禄",
    ["&mayunlu"] = "马云禄",
    ["#mayunlu"] = "剑胆琴心",
    ["~mayunlu"] = "呜呜呜~~~是你们欺负人。",
    ["mashu_mayunlu"] = "马术",
    ["fengpo"] = "凤魄",
    [":fengpo"] = "当你使用【杀】或【决斗】仅指定一名角色为目标后，你可以观看其手牌然后选择一项：1.摸X张牌；2.你使用此牌造成的伤害+X。（X为其方块手牌数，若你本局游戏内杀死过角色，则修改为其红色手牌数）",
    ["$fengpo1"] = "等我提枪上马，打你个落花流水。",
    ["$fengpo2"] = "对付你，用不着我家哥哥亲自上阵。",
    ["fengpo:draw"] = "摸X张牌",
    ["fengpo:addDamage"] = "你使用此牌造成的伤害+X",
    ["$fengpo_addDamage"] = "%from 执行了“%arg”的效果，%card 伤害值 %arg2",
    ["$fengpo_upgrade"] = "%from 杀死了 %to，%from 在本局游戏内杀死过角色，“%arg”技能描述中的X修改为其红色手牌数"
}
return {sp3}

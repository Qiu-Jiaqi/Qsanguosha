extension = sgs.Package("sp3", sgs.Package_GeneralPack)
-- 马云禄
mayunlu = sgs.General(extension, "mayunlu", "shu", "4", true, true)
-- 马术：锁定技，你与其他角色距离-1。
mashu_mayunlu =
    sgs.CreateDistanceSkill {
    name = "mashu_mayunlu",
    correct_func = function(self, from, to)
        if from:hasShownSkill(self:objectName()) then
            return -1
        end
        return 0
    end
}
-- 凤魄：当你使用【杀】或【决斗】仅指定一名角色为目标后，你可以观看其手牌然后选择一项：1.摸X张牌；2.此牌造成的伤害+X。
--      （X为其方块手牌数，若你本局游戏内杀死过角色，则修改为其红色手牌数）
fengpo =
    sgs.CreateTriggerSkill {
    name = "fengpo",
    events = {sgs.TargetConfirmed},
    can_trigger = function(self, event, room, player, data)
        if
            player and player:isAlive() and player:hasSkill(self:objectName()) and data:toCardUse().from == player and
                data:toCardUse().to:length() == 1 and
                (data:toCardUse().card:isKindOf("Slash") or data:toCardUse().card:isKindOf("Duel"))
         then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        local target = data:toCardUse().to:at(0)
        room:showAllCards(target, player)
        local choices = {"draw", "damage"}
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
            player:drawCards(x, self:objectName())
        elseif choice == "damage" then
            room:setTag("fengpo_addDamage", sgs.QVariant(x))
        end
        return false
    end
}
fengpo_addDamage =
    sgs.CreateTriggerSkill {
    name = "#fengpo_addDamage",
    events = {sgs.ConfirmDamage},
    can_trigger = function(self, event, room, player, data)
        if
            player and player:isAlive() and player:hasShownSkill("fengpo") and
                room:getTag("fengpo_addDamage"):toInt() ~= 0
         then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        room:sendCompulsoryTriggerLog(player, "fengpo", true)
        room:broadcastSkillInvoke("fengpo")
        return true
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        local damage = data:toDamage()
        local msg = sgs.LogMessage()
        msg.type = "$fengpo_addDamage"
        msg.from = player
        msg.arg = "fengpo"
        -- 什么玩意，这句没有问题啊，加上这句就不能发消息，bug搞了一个小时多还是没能解决
        -- 已解决，msg.type以后使用$
        msg.card_str = damage.card:toString()
        msg.arg2 = "+" .. room:getTag("fengpo_addDamage"):toInt()
        room:sendLog(msg)
        damage.damage = damage.damage + room:getTag("fengpo_addDamage"):toInt()
        room:removeTag("fengpo_addDamage")
        data:setValue(damage)
        return false
    end
}
fengpo_upgrade =
    sgs.CreateTriggerSkill {
    name = "#fengpo_upgrade",
    events = {sgs.BuryVictim},
    can_trigger = function(self, event, room, player, data)
        local mayunlu = room:findPlayerBySkillName("fengpo")
        if
            mayunlu and mayunlu:isAlive() and data:toDeath().damage.from == mayunlu and
                mayunlu:getMark("fengpo_upgrade") == 0
         then
            return self:objectName(), mayunlu
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        room:broadcastSkillInvoke("fengpo")
        return true
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        room:addPlayerMark(ask_who, "fengpo_upgrade")
        local msg = sgs.LogMessage()
        msg.type = "$fengpo_upgrade"
        msg.from = ask_who
        msg.to:append(player)
        msg.arg = "fengpo"
        room:sendLog(msg)
        return false
    end
}
mayunlu:addSkill(mashu_mayunlu)
mayunlu:addSkill(fengpo)
mayunlu:addSkill(fengpo_addDamage)
mayunlu:addSkill(fengpo_upgrade)
sgs.insertRelatedSkills(extension, fengpo, fengpo_addDamage, fengpo_upgrade)
sgs.LoadTranslationTable {
    ["sp3"] = "sp3",
    ["mayunlu"] = "马云禄",
    ["&mayunlu"] = "马云禄",
    ["#mayunlu"] = "剑胆琴心",
    ["~mayunlu"] = "呜呜呜~~~是你们欺负人",
    ["mashu_mayunlu"] = "马术",
    ["fengpo"] = "凤魄",
    [":fengpo"] = "当你使用【杀】或【决斗】仅指定一名角色为目标后，你可以观看其手牌然后选择一项：1.摸X张牌；2.此牌造成的伤害+X。（X为其方块手牌数，若你本局游戏内杀死过角色，则修改为其红色手牌数）",
    ["$fengpo1"] = "等我提枪上马，打你个落花流水。",
    ["$fengpo2"] = "对付你，用不着我家哥哥亲自上阵。",
    ["fengpo:draw"] = "摸X张牌",
    ["fengpo:damage"] = "此牌造成的伤害+X",
    -- 破案了，bug原来是因为#，用$就可以了，以后的房间信息，都用$
    -- ["#fengpo_addDamage"] = "%from 执行了“%arg”的效果，%card 伤害值 %arg2"
    ["$fengpo_addDamage"] = "%from 执行了“%arg”的效果，%card 伤害值 %arg2",
    ["$fengpo_upgrade"] = "%from 杀死了 %to，%from 在本局游戏内杀死过角色，“%arg”技能描述中的X修改为其红色手牌数。"
}
return {extension}

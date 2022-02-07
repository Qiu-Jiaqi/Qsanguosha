yjcm4 = sgs.Package("yjcm4", sgs.Package_GeneralPack)
sgs.LoadTranslationTable {
    ["yjcm4"] = "一将成名4"
}
-- 沮授，与据守拼音一致，改为我用的自然码双拼命名
juub = sgs.General(yjcm4, "juub", "qun", "3", true, true)
-- 渐营：每当你使用（不包括响应）一张牌时，若此牌与你使用的上一张牌花色或点数相同，你可以摸一张牌。
jianying =
    sgs.CreateTriggerSkill {
    name = "jianying",
    events = sgs.CardUsed,
    can_trigger = function(self, event, room, player, data)
        -- 当前使用的牌
        local card = data:toCardUse().card
        if
            player and player:isAlive() and player:hasSkill(self:objectName()) and data:toCardUse().from == player and
                card:getTypeId() ~= sgs.Card_TypeSkill and
                card:getNumber() ~= 0 and
                card:getSuit() ~= sgs.Card_NoSuit
         then
            -- 上次使用的牌
            local last = room:getTag("jianying_card"):toCard()
            -- 存储当前使用的牌
            local card_data = sgs.QVariant()
            card_data:setValue(card)
            room:setTag("jianying_card", card_data)
            -- local msg = sgs.LogMessage()
            -- msg.type = "$test_jianying"
            -- msg.arg = card:getNumber()
            -- room:sendLog(msg)
            -- msg.arg = card:getSuitString()
            -- room:sendLog(msg)
            if last and (card:getNumber() == last:getNumber() or card:getSuit() == last:getSuit()) then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        return player:askForSkillInvoke(self:objectName(), data)
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        room:broadcastSkillInvoke(self:objectName())
        room:drawCards(player, 1, self:objectName())
        return false
    end
}
-- 矢北: 锁定技，你每回合第一次受到伤害后，回复1点体力。然后进行判定，根据判定结果决定本回合下次技能效果：
--       若为红色，技能效果不变；若为黑色，改为失去1点体力。
shibei =
    sgs.CreateMasochismSkill {
    name = "shibei",
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName()) then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data)
    end,
    on_damaged = function(self, player, damage)
        local room = player:getRoom()
        room:sendCompulsoryTriggerLog(player, self:objectName(), true)
        room:broadcastSkillInvoke(self:objectName())
        -- 若为本回合第一次发动
        if not player:hasFlag(self:objectName()) then
            local recover = sgs.RecoverStruct()
            recover.who = player
            room:recover(player, recover)
            player:setFlags(self:objectName())
        else
            if room:getTag("shibei_good"):toBool() then
                local recover = sgs.RecoverStruct()
                recover.who = player
                room:recover(player, recover)
            else
                room:loseHp(player, 1)
            end
        end
        local judge = sgs.JudgeStruct()
        judge.who = player
        judge.reason = self:objectName()
        judge.play_animation = false
        judge.pattern = ".|red"
        judge.good = true
        room:judge(judge)
        if judge:isGood() then
            room:setTag("shibei_good", sgs.QVariant(true))
        else
            room:setTag("shibei_good", sgs.QVariant(false))
        end
    end
}
juub:addSkill(jianying)
juub:addSkill(shibei)
sgs.LoadTranslationTable {
    ["juub"] = "沮授",
    ["&juub"] = "沮授",
    ["#juub"] = "监军谋国",
    ["~juub"] = "志士凋亡，河北哀矣。",
    -- ["$test_jianying"] = "%arg test",
    ["jianying"] = "渐营",
    [":jianying"] = "每当你使用（不包括响应）一张牌时，若此牌与你使用的上一张牌花色或点数相同，你可以摸一张牌。",
    ["$jianying1"] = "由缓至急，循循而进。",
    ["$jianying2"] = "事须缓图，欲速不达也。",
    ["shibei"] = "矢北",
    [":shibei"] = "锁定技，你每回合第一次受到伤害后，回复1点体力。然后进行判定，根据判定结果决定本回合下次技能效果：若为红色，技能效果不变；若为黑色，改为失去1点体力。",
    ["$shibei1"] = "矢志于北，尽忠于国。",
    ["$shibei2"] = "命系袁氏，一心向北。"
}
return {yjcm4}

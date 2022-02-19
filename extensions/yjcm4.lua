yjcm4 = sgs.Package("yjcm4", sgs.Package_GeneralPack)
sgs.LoadTranslationTable {
    ["yjcm4"] = "一将成名4"
}
-- 沮授，与据守拼音一致，改为我用的自然码双拼命名
juub = sgs.General(yjcm4, "juub", "qun", "3", true, true)
-- 渐营：每当你使用（包括响应）一张牌时，若此牌与你使用的上一张牌花色或点数相同，你可以摸一张牌。
-- 出牌阶段限一次，你可以将一张牌当做任意一张基本牌使用，且该牌使用不计入次数限制，若你使用的上一张牌有花色，则此牌的花色视为与上一张牌的花色相同，否则花色不变。
jianying_vs =
    sgs.CreateOneCardViewAsSkill {
    name = "jianying",
    filter_pattern = ".",
    view_as = function(self, card)
        local last = sgs.Self:getTag("jianying_card"):toCard()
        local suit = card:getSuit()
        -- 若上一张牌有花色
        if last and last:getSuit() ~= sgs.Card_NoSuit and last:getSuit() ~= sgs.Card_SuitToBeDecided then
            suit = last:getSuit()
        end
        local new_card = sgs.Sanguosha:cloneCard(sgs.Self:getTag(self:objectName()):toString(), suit, card:getNumber())
        new_card:addSubcard(card)
        new_card:setSkillName(self:objectName())
        new_card:setShowSkill(self:objectName())
        -- 记录本回合已发动
        sgs.Self:setFlags(self:objectName())
        return new_card
    end,
    enabled_at_play = function(self, player)
        return not sgs.Self:hasFlag(self:objectName())
    end
}
jianying =
    sgs.CreateTriggerSkill {
    name = "jianying",
    view_as_skill = jianying_vs,
    guhuo_type = "b",
    events = {sgs.CardUsed, sgs.CardResponded, sgs.PreCardUsed},
    on_record = function(self, event, room, player, data)
        if
            event == sgs.PreCardUsed and player and player:isAlive() and player:hasSkill(self:objectName()) and
                data:toCardUse().card:getSkillName() == self:objectName()
         then
            -- 不计入次数限制
            local use = data:toCardUse()
            room:addPlayerHistory(player, use.card:getClassName(), -1)
            use.m_addHistory = false
            data:setValue(use)
        end
    end,
    can_trigger = function(self, event, room, player, data)
        -- 当前使用的牌
        local card = event == sgs.CardResponded and data:toCardResponse().m_card or data:toCardUse().card
        if
            -- 注意：事件更改时，这里需要改，这里应该是包括sgs.CardUsed和sgs.CardResponded
            event ~= sgs.PreCardUsed and player and player:isAlive() and player:hasSkill(self:objectName()) and
                -- 这个判断就是多余的，player拥有技能就肯定能发动了
                -- data:toCardUse().from == player and
                card and
                card:getTypeId() ~= sgs.Card_TypeSkill
         then
            -- 这张牌有无花色、点数都要存
            -- card:getNumber() ~= 0 and
            -- card:getSuit() ~= sgs.Card_NoSuit and
            -- card:getSuit() ~= sgs.Card_SuitToBeDecided
            -- 上次使用的牌
            local last = sgs.Self:getTag("jianying_card"):toCard()
            -- 存储当前使用的牌
            local card_data = sgs.QVariant()
            card_data:setValue(card)
            sgs.Self:setTag("jianying_card", card_data)
            -- local msg = sgs.LogMessage()
            -- msg.type = "$test_jianying"
            -- msg.arg = card:getNumber()
            -- room:sendLog(msg)
            -- msg.arg = card:getSuitString()
            -- room:sendLog(msg)
            -- 花色、点数不为空在这里判断才对，若花色、点数都为空，则肯定不能，有一个不为空则可与上一张牌比较
            if
                card:getNumber() == 0 and
                    (card:getSuit() == sgs.Card_NoSuit or card:getSuit() == sgs.Card_SuitToBeDecided)
             then
                return ""
            end
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
    ["jianying"] = "渐营",
    [":jianying"] = "每当你使用（包括响应）一张牌时，若此牌与你使用的上一张牌花色或点数相同，你可以摸一张牌。出牌阶段限一次，你可以将一张牌当做任意一张基本牌使用，且该牌使用不计入次数限制，若你使用的上一张牌有花色，则此牌的花色视为与上一张牌的花色相同，否则花色不变。",
    ["$jianying1"] = "由缓至急，循循而进。",
    ["$jianying2"] = "事须缓图，欲速不达也。",
    ["shibei"] = "矢北",
    [":shibei"] = "锁定技，你每回合第一次受到伤害后，回复1点体力。然后进行判定，根据判定结果决定本回合下次技能效果：若为红色，技能效果不变；若为黑色，改为失去1点体力。",
    ["$shibei1"] = "矢志于北，尽忠于国。",
    ["$shibei2"] = "命系袁氏，一心向北。"
}
return {yjcm4}

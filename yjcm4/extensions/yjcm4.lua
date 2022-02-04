extension = sgs.Package("yjcm4", sgs.Package_GeneralPack)
-- 沮授，与据守拼音一致，改为我用的自然码双拼命名
juub = sgs.General(extension, "juub", "qun", "3", true, true)
-- 渐营：原：每当你于出牌阶段内使用一张牌时，若此牌与你本阶段使用的上一张牌花色或点数相同，你可以摸一张牌。
--       现：每当你使用（不包括响应）一张牌时，若此牌与你使用的上一张牌花色或点数相同，你可以摸一张牌。
-- 本来想设计成包括响应的，但是响应的结构体中只有m_who（被响应者），不能判断出响应牌的是谁，尝试了好久，无法实现，就放弃了。
jianying =
    sgs.CreateTriggerSkill {
    name = "jianying",
    events = {sgs.CardUsed},
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
            local last = room:getTag(self:objectName() .. "card"):toCard()
            local card_data = sgs.QVariant()
            card_data:setValue(card)
            room:setTag(self:objectName() .. "card", card_data)
            -- local msg = sgs.LogMessage()
            -- msg.type = "$test"
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
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        player:drawCards(1, self:objectName())
        return false
    end
}
-- 矢北: 原：锁定技，每当你于一名角色的回合内受到伤害后，若为你本回合第一次受到伤害，你回复1点体力，否则你失去1点体力。
--       现：锁定技，你每回合第一次受到伤害后，回复1点体力。然后进行判定，根据判定结果决定本回合下次技能效果：
--           若为红色，技能效果不变；若为黑色，改为失去1点体力。
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
        if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data) then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true)
            room:broadcastSkillInvoke(self:objectName())
            return true
        end
        return false
    end,
    on_damaged = function(self, player, damage)
        local room = player:getRoom()
        -- 若为本回合第一次发动
        if not player:hasFlag(self:objectName()) then
            local recover = sgs.RecoverStruct()
            recover.who = player
            room:recover(player, recover)
            room:setPlayerFlag(player, self:objectName())
        else
            if room:getTag(self:objectName()):toBool() then
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
        -- 默认为true，显示生效绿色的勾勾或者失效红色的叉叉，这里不需要生不生效，只要判定结果的颜色
        judge.play_animation = false
        judge.pattern = ".|red"
        judge.good = true
        room:judge(judge)
        if judge:isGood() then
            room:setTag(self:objectName(), sgs.QVariant(true))
        else
            room:setTag(self:objectName(), sgs.QVariant(false))
        end
    end
}
juub:addSkill(jianying)
juub:addSkill(shibei)
sgs.LoadTranslationTable {
    ["yjcm4"] = "一将成名4",
    ["juub"] = "沮授",
    ["&juub"] = "沮授",
    ["#juub"] = "监军谋国",
    ["~juub"] = "志士凋亡，河北哀矣。",
    -- ["$test"] = "%arg test",
    ["jianying"] = "渐营",
    [":jianying"] = "每当你使用（不包括响应）一张牌时，若此牌与你使用的上一张牌花色或点数相同，你可以摸一张牌。",
    ["$jianying1"] = "由缓至急，循循而进。",
    ["$jianying2"] = "事须缓图，欲速不达也。",
    ["shibei"] = "矢北",
    [":shibei"] = "锁定技，你每回合第一次受到伤害后，回复1点体力。然后进行判定，根据判定结果决定本回合下次技能效果：若为红色，技能效果不变；若为黑色，改为失去1点体力。",
    ["$shibei1"] = "矢志于北，尽忠于国。",
    ["$shibei2"] = "命系袁氏，一心向北。"
}
return {extension}

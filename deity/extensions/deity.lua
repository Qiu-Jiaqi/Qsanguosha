extension = sgs.Package("deity", sgs.Package_GeneralPack)
sgs.LoadTranslationTable {
    ["deity"] = "神包"
}
-- 神甄姬
shenzhenji = sgs.General(extension, "shenzhenji", "careerist", "4", false, true)
-- 神赋：回合结束时，若你的手牌数为：奇数，你可对一名其他角色造成1点雷电伤害，若造成其死亡，你可重复此流程；
--      偶数，你可令一名本回合未指定过的角色摸一张牌或弃置其一张手牌，若执行后该角色的手牌数等于其体力值，你可重复此流程。
shenfu =
    sgs.CreateTriggerSkill {
    name = "shenfu",
    events = sgs.EventPhaseStart,
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        local targets = room:getAlivePlayers()
        if player:getHandcardNum() % 2 == 0 then
            while not targets:isEmpty() do
                -- 询问选择目标
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@shenfu_ou", true, true)
                if target then
                    -- 亮将
                    player:showSkill(self:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    local choices = {"draw"}
                    if player:canDiscard(target, "h") then
                        table.insert(choices, "discard")
                    end
                    -- 询问选择
                    local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                    if choice == "draw" then
                        target:drawCards(1, self:objectName())
                    else
                        -- 询问选择弃置卡牌
                        local id =
                            room:askForCardChosen(player, target, "h", self:objectName(), false, sgs.Card_MethodDiscard)
                        room:throwCard(id, target, player)
                    end
                    -- 移除指定过的目标
                    targets:removeOne(target)
                    if target:getHandcardNum() ~= target:getHp() then
                        break
                    end
                else
                    break
                end
            end
        else
            -- 移除自己
            targets:removeOne(player)
            while not targets:isEmpty() do
                -- 询问选择目标
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@shenfu_ji", true, true)
                if target then
                    -- 亮将
                    player:showSkill(self:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Thunder))
                    -- 移除指定过的目标
                    targets:removeOne(target)
                    if target:isAlive() then
                        break
                    end
                else
                    break
                end
            end
        end
        return false
    end
}
-- 七弦：锁定技，你的手牌上限为7。
qixian =
    sgs.CreateMaxCardsSkill {
    name = "qixian",
    fixed_func = function(self, player)
        return player:hasShownSkill(self:objectName()) and 7 or -1
    end
}
-- 用于未亮将时回合结束询问是否发动七弦
qixian_trigger =
    sgs.CreatePhaseChangeSkill {
    name = "#qixian",
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if
            player and player:isAlive() and player:hasSkill(self:objectName()) and
                not player:hasShownSkill(self:objectName()) and
                player:getPhase() == sgs.Player_Discard and
                player:getHandcardNum() > player:getHp()
         then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        return player:askForSkillInvoke(self:objectName(), data) and true or false
    end,
    on_phasechange = function(self, player)
        player:showSkill("qixian")
        return false
    end
}
shenzhenji:addSkill(shenfu)
shenzhenji:addSkill(qixian)
shenzhenji:addSkill(qixian_trigger)
sgs.insertRelatedSkills(extension, qixian, qixian_trigger)
sgs.LoadTranslationTable {
    ["shenzhenji"] = "神甄姬",
    ["&shenzhenji"] = "神甄姬",
    ["#shenzhenji"] = "洛水凌波",
    ["~shenzhenji"] = "众口铄金，难证吾清。",
    ["shenfu"] = "神赋",
    [":shenfu"] = "回合结束时，若你的手牌数为：奇数，你可对一名其他角色造成1点雷电伤害，若造成其死亡，你可重复此流程；偶数，你可令一名本回合未指定过的角色摸一张牌或弃置其一张手牌，若执行后该角色的手牌数等于其体力值，你可重复此流程。",
    ["@shenfu_ou"] = "你可以发动“神赋”，选择一名角色，令其摸一张牌或弃置其一张手牌。",
    ["@shenfu_ji"] = "你可以发动“神赋”，选择一名其他角色，对其造成1点雷电伤害。",
    ["shenfu:draw"] = "令其摸一张牌",
    ["shenfu:discard"] = "弃置其一张手牌",
    ["$shenfu1"] = "河洛之神，诗赋可抒。",
    ["$shenfu2"] = "云神鱼游，罗扇掩面。",
    ["qixian"] = "七弦",
    ["#qixian"] = "七弦",
    [":qixian"] = "锁定技，你的手牌上限为7。"
}
return {extension}

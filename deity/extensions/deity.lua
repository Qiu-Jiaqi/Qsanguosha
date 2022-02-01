extension = sgs.Package("deity", sgs.Package_GeneralPack)
-- 神将还是野心家势力吧
-- 神甄姬看似弱，但也比一般的强吧
-- 神甄姬
shenzhenji = sgs.General(extension, "shenzhenji", "careerist", "4", false, true)
-- 神赋：回合结束时，若你的手牌数为：奇数，你可对一名其他角色造成1点雷电伤害，若造成其死亡，你可重复此流程；
--    偶数，你可令一名角色摸一张牌或你弃置其一张手牌，若执行后该角色的手牌数等于其体力值，你可重复此流程（不能对本回合指定过的目标使用）。
shenfu =
    sgs.CreatePhaseChangeSkill {
    name = "shenfu",
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        if player:askForSkillInvoke(self:objectName()) then
            return true
        end
        return false
    end,
    on_phasechange = function(self, player)
        local room = player:getRoom()
        local targets = room:getAlivePlayers()
        if player:getHandcardNum() % 2 == 0 then
            while true do
                -- 询问选择目标
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@shenfu_ou", true, true)
                if target then
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
                        -- 询问选择卡牌
                        local id =
                            room:askForCardChosen(player, target, "h", self:objectName(), false, sgs.Card_MethodDiscard)
                        room:throwCard(id, target, player)
                    end
                    -- 移除已发动过的目标
                    targets:removeOne(target)
                    if target:getHandcardNum() ~= target:getHp() then
                        break
                    end
                end
            end
        else
            -- 移除自己
            targets:removeOne(player)
            while true do
                -- 询问选择目标
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@shenfu_ji", true, true)
                if target then
                    room:broadcastSkillInvoke(self:objectName())
                    room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Thunder))
                    -- 移除已发动过的目标
                    targets:removeOne(target)
                    if target:isAlive() then
                        break
                    end
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
        return player:hasSkill(self:objectName()) and 7 or -1
    end
}
shenzhenji:addSkill(shenfu)
shenzhenji:addSkill(qixian)
sgs.LoadTranslationTable {
    ["deity"] = "神包",
    ["shenzhenji"] = "神甄姬",
    ["&shenzhenji"] = "神甄姬",
    ["#shenzhenji"] = "洛水凌波",
    ["~shenzhenji"] = "众口铄金，难证吾清。",
    ["shenfu"] = "神赋",
    [":shenfu"] = "回合结束时，若你的手牌数为：奇数，你可对一名其他角色造成1点雷电伤害，若造成其死亡，你可重复此流程；偶数，你可令一名角色摸一张牌或你弃置其一张手牌，若执行后该角色的手牌数等于其体力值，你可重复此流程（不能对本回合指定过的目标使用）。",
    ["@shenfu_ou"] = "你可以发动“神赋”，选择一名角色，令其摸一张牌或弃置一张牌。",
    ["@shenfu_ji"] = "你可以发动“神赋”，选择一名其他角色，对其造成1点雷电伤害。",
    ["shenfu:draw"] = "令其摸一张牌",
    ["shenfu:discard"] = "弃置其一张牌",
    ["$shenfu1"] = "河洛之神，诗赋可抒。",
    ["$shenfu2"] = "云神鱼游，罗扇掩面。",
    ["qixian"] = "七弦",
    [":qixian"] = "锁定技，你的手牌上限为7。"
}
return {extension}

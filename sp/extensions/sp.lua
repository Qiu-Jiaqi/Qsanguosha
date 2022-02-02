extension = sgs.Package("sp", sgs.Package_GeneralPack)
-- 戏志才
xizhicai = sgs.General(extension, "xizhicai", "wei", "3", true, true)
-- 天妒：当你的判定结果确定后，你可获得判定牌。
tiandu_xizhicai =
    sgs.CreateTriggerSkill {
    name = "tiandu_xizhicai",
    events = {sgs.FinishJudge},
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName()) then
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
        player:obtainCard(data:toJudge().card)
        return false
    end
}
-- 先辅：锁定技，亮将时，你选择一名其他角色，当其受到伤害后，你受到等量的伤害，当其回复体力后，你回复等量的体力。
xianfu =
    sgs.CreateTriggerSkill {
    name = "xianfu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damaged, sgs.HpRecover},
    can_trigger = function(self, event, room, player, data)
        local xizhicai = room:findPlayerBySkillName(self:objectName())
        if player and player:isAlive() and player:getMark("@xianfu") > 0 then
            return self:objectName(), xizhicai
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        room:sendCompulsoryTriggerLog(ask_who, self:objectName(), true)
        room:broadcastSkillInvoke(self:objectName())
        return true
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        if event == sgs.Damaged then
            room:damage(
                sgs.DamageStruct(self:objectName(), nil, ask_who, data:toDamage().damage, sgs.DamageStruct_Normal)
            )
        else
            local recover = sgs.RecoverStruct()
            recover.who = ask_who
            recover.recover = data:toRecover().recover
            room:recover(ask_who, recover)
        end
        return false
    end
}
xianfu_target =
    sgs.CreateTriggerSkill {
    name = "#xianfu_target",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GeneralShown},
    can_trigger = function(self, event, room, player, data)
        -- 使用标记检查是否未发动
        if player and player:isAlive() and player:hasShownSkill("xianfu") and player:getMark(self:objectName()) == 0 then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        room:sendCompulsoryTriggerLog(player, "xianfu", true)
        room:broadcastSkillInvoke("xianfu")
        return true
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        -- 第五个参数false表示必须选择
        local target =
            room:askForPlayerChosen(player, room:getOtherPlayers(player), "xianfu", "@xianfu_choose", false, true)
        -- 标记先辅选择的角色
        target:addMark("@xianfu")
        -- 使用标记，记录已发动
        player:addMark(self:objectName())
        return false
    end
}
-- 筹策：当你受到1点伤害后，你可以判定，若结果为：黑色，你弃置一名角色区域里的一张牌；红色，你令一名角色摸一张牌（先辅的角色摸两张）。
chouce =
    sgs.CreateMasochismSkill {
    name = "chouce",
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName()) then
            res = self:objectName()
            for i = 2, data:toDamage().damage, 1 do
                res = res .. "," .. self:objectName()
            end
            return res
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
    on_damaged = function(self, player, damage)
        local room = player:getRoom()
        local judge = sgs.JudgeStruct()
        judge.who = player
        judge.reason = self:objectName()
        judge.play_animation = true
        room:judge(judge)
        if judge.card:isRed() then
            local target =
                room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@chouce_draw", true, true)
            if target then
                -- 若为先辅选择的角色
                if target:getMark("@xianfu") > 0 then
                    room:drawCards(target, 2, self:objectName())
                else
                    room:drawCards(target, 1, self:objectName())
                end
            end
        else
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                -- if not p:isAllNude() then
                -- 这里还是用能否弃置判断较直观
                if player:canDiscard(p, "hej") then
                    targets:append(p)
                end
            end
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@chouce_discard", true, true)
            if target then
                -- 不能用这个函数，这个是目标选择弃置手牌和装备牌，最后的true表示包括装备牌
                -- room:askForDiscard(target, self:objectName(), 1, 1, false, true)
                -- 参数：（目标，原因，弃牌数，最小弃牌数，是否强制弃牌，是否包括装备，提示信息）
                local id = -- 询问选择弃置的牌，包括手牌、装备区牌、判定区牌
                    room:askForCardChosen(player, target, "hej", self:objectName(), false, sgs.Card_MethodDiscard)
                -- 参数：（选择者，弃置目标，区域，原因，手牌是否可见，处理方法，不能选择的牌id列表）
                room:throwCard(id, target, player, self:objectName())
            end
        end
    end
}
xizhicai:addSkill(tiandu_xizhicai)
xizhicai:addSkill(xianfu)
xizhicai:addSkill(xianfu_target)
-- 组合技能，这里开始不会用，花了太多时间摸索
sgs.insertRelatedSkills(extension, xianfu, xianfu_target)
-- extension:insertRelatedSkills("xianfu", "#xianfu_target")
xizhicai:addSkill(chouce)
sgs.LoadTranslationTable {
    ["sp"] = "sp",
    ["xizhicai"] = "戏志才",
    ["&xizhicai"] = "戏志才",
    ["#xizhicai"] = "负俗的天才",
    ["~xizhicai"] = "为何……不再给我……一点点时间……",
    ["tiandu_xizhicai"] = "天妒",
    -- 技能描述只需用下划线前的，_应该是用来区分相同技能的不同武将。
    -- [":tiandu"] = "当你的判定结果确定后，你可获得判定牌。 ",
    ["$tiandu_xizhicai1"] = "既是如此~",
    ["$tiandu_xizhicai2"] = "天意，不可逆~",
    ["xianfu"] = "先辅",
    [":xianfu"] = "锁定技，游戏开始时，你选择一名其他角色，当其受到伤害后，你受到等量的伤害，当其回复体力后，你回复等量的体力。 ",
    ["$xianfu1"] = "辅佐明君，从一而终。",
    ["$xianfu2"] = "吾于此生，竭尽所能。",
    ["@xianfu_choose"] = "发动“先辅”，选择一名其他角色。",
    ["@xianfu"] = "先辅",
    ["chouce"] = "筹策",
    [":chouce"] = "当你受到1点伤害后，你可以判定，若结果为：黑色，你弃置一名角色区域里的一张牌；红色，你令一名角色摸一张牌（先辅的角色摸两张）。 ",
    ["$chouce1"] = "一筹一划，一策一略。",
    ["$chouce2"] = "主公之忧，吾之所思也。",
    ["@chouce_draw"] = "你可以发动“筹策”，选择一名角色，令其摸一张牌（先辅的角色摸两张）。",
    ["@chouce_discard"] = "你可以发动“筹策”，选择一名角色，弃置其区域里的一张牌。"
}
return {extension}

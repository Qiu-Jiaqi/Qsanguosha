extension = sgs.Package("sp", sgs.Package_GeneralPack)
sgs.LoadTranslationTable {
    ["sp"] = "sp"
}
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
    [":xianfu"] = "锁定技，游戏开始时，你选择一名其他角色，当其受到伤害后，你受到等量的伤害，当其回复体力后，你回复等量的体力。",
    ["$xianfu1"] = "辅佐明君，从一而终。",
    ["$xianfu2"] = "吾于此生，竭尽所能。",
    ["@xianfu_choose"] = "发动“先辅”，选择一名其他角色。",
    ["@xianfu"] = "先辅",
    ["chouce"] = "筹策",
    [":chouce"] = "当你受到1点伤害后，你可以判定，若结果为：黑色，你弃置一名角色区域里的一张牌；红色，你令一名角色摸一张牌（先辅的角色摸两张）。",
    ["$chouce1"] = "一筹一划，一策一略。",
    ["$chouce2"] = "主公之忧，吾之所思也。",
    ["@chouce_draw"] = "你可以发动“筹策”，选择一名角色，令其摸一张牌（先辅的角色摸两张）。",
    ["@chouce_discard"] = "你可以发动“筹策”，选择一名角色，弃置其区域里的一张牌。"
}
-- 张星彩
zhangxingcai = sgs.General(extension, "zhangxingcai", "shu", "3", false, true)
-- 甚贤：每当一名其他角色于你的回合外因弃置而失去基本牌后，你可以摸一张牌。
--       我吐了，整了一早上，反正我是吐了，卡牌移动原因的结构体，什么鬼作用都没有的，用不了，一早上白白浪费时间
-- shenxian =
--     sgs.CreateTriggerSkill {
--     name = "shenxian",
--     events = {sgs.BeforeCardsMove},
--     can_trigger = function(self, event, room, player, data)
--         local zhangxingcai = room:findPlayerBySkillName(self:objectName())
--         if zhangxingcai and zhangxingcai:isAlive() and zhangxingcai:hasSkill(self:objectName()) then
--             local move = data:toMoveOneTime()
--             if move.from and move.from:objectName() ~= zhangxingcai:objectName() then
--                 return ""
--             end
--             --     zhangxingcai ~= player and
--             --     zhangxingcai:getPhase() == sgs.Player_NotActive and
--             if
--                 bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ==
--                     sgs.CardMoveReason_S_REASON_DISCARD
--              then
--                 -- local reason = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
--                 for _, id in sgs.qlist(move.card_ids) do
--                     if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
--                         return self:objectName(), zhangxingcai
--                     end
--                 end
--             end
--         end
--         return ""
--     end,
--     on_cost = function(self, event, room, player, data, ask_who)
--         if ask_who:askForSkillInvoke(self:objectName(), data) then
--             room:broadcastSkillInvoke(self:objectName())
--             return true
--         end
--         return false
--     end,
--     on_effect = function(self, event, room, player, data, ask_who)
--         ask_who:drawCards(1, self:objectName())
--         return false
--     end
-- }
-- 放弃了，改技能呗
-- 甚贤：每当一名其他角色在其回合内造成过伤害，你可以摸一张牌。
shenxian =
    sgs.CreateTriggerSkill {
    name = "shenxian",
    events = {sgs.Damage, sgs.EventPhaseEnd},
    can_trigger = function(self, event, room, player, data)
        local zhangxingcai = room:findPlayerBySkillName(self:objectName())
        if zhangxingcai and zhangxingcai:isAlive() and zhangxingcai:hasSkill(self:objectName()) then
            if player ~= zhangxingcai and event == sgs.Damage then
                room:setPlayerFlag(player, self:objectName())
            elseif
                event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish and
                    player:hasFlag(self:objectName())
             then
                return self:objectName(), zhangxingcai
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        if ask_who:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        ask_who:drawCards(1, self:objectName())
        return false
    end
}
-- 枪舞：出牌阶段限一次，你可以进行判定：若如此做，直到下回合开始前，你使用点数小于判定牌点数的【杀】无距离限制，
--      你使用点数大于判定牌点数的【杀】无次数限制且不计入次数限制，你使用点数等于判定牌点数的【杀】同时具备以上两点且伤害+1。
qiangwu_card =
    sgs.CreateSkillCard {
    name = "qiangwu",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local judge = sgs.JudgeStruct()
        judge.who = source
        judge.reason = self:objectName()
        judge.play_animation = false
        room:judge(judge)
        room:setPlayerMark(source, self:objectName(), judge.card:getNumber())
    end
}
qiangwu_vs =
    sgs.CreateZeroCardViewAsSkill {
    name = "qiangwu",
    view_as = function(self)
        local card = qiangwu_card:clone()
        card:setSkillName(self:objectName())
        -- 用于亮将
        card:setShowSkill(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#qiangwu")
    end
}
qiangwu =
    sgs.CreateTriggerSkill {
    name = "qiangwu",
    view_as_skill = qiangwu_vs,
    events = {sgs.EventPhaseStart, sgs.PreCardUsed, sgs.ConfirmDamage},
    can_trigger = function(self, event, room, player, data)
        -- 只有进行了判定，设置了mark，才有必要进行回合结束mark置零、使用杀时判断等操作
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getMark(self:objectName()) ~= 0 then
            if
                (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_NotActive) or
                    (event == sgs.PreCardUsed and data:toCardUse().card:isKindOf("Slash") and
                        data:toCardUse().card:getNumber() >= player:getMark(self:objectName())) or
                    (event == sgs.ConfirmDamage and data:toDamage().card:isKindOf("Slash") and
                        data:toDamage().card:getNumber() == player:getMark(self:objectName()))
             then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        return player:hasShownSkill(self:objectName()) and true or false
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        -- 以下判断在can_trigger已写
        if event == sgs.EventPhaseStart then
            -- 回合结束，mark置零
            room:setPlayerMark(player, self:objectName(), 0)
        elseif event == sgs.PreCardUsed then
            -- >=点数的杀，不计入次数限制
            local use = data:toCardUse()
            room:addPlayerHistory(player, use.card:getClassName(), -1)
            use.m_addHistory = false
            data:setValue(use)
        elseif event == sgs.ConfirmDamage then
            -- =点数的杀，伤害值+1
            local damage = data:toDamage()
            damage.damage = damage.damage + 1
            data:setValue(damage)
            local msg = sgs.LogMessage()
            msg.type = "$qiangwu_addDamage"
            msg.from = player
            msg.arg = "qiangwu"
            msg.card_str = damage.card:toString()
            msg.arg2 = "+1"
            room:sendLog(msg)
        end
        return false
    end
}
qiangwu_mod =
    sgs.CreateTargetModSkill {
    name = "#qiangwu_mod",
    distance_limit_func = function(self, player, card)
        local n = player:getMark("qiangwu")
        if n ~= 0 and card:getNumber() ~= 0 and card:getNumber() <= n then
            return 732
        end
        return 0
    end,
    -- 用History才能实现技能中描述的不计次数限制，只用这种的话，先用了>=的牌，再用<的则不可以，就是计入了次数了
    -- 但也必须写这个，不然用了<的，再用>=的又不能再用了
    residue_func = function(self, player, card)
        local n = player:getMark("qiangwu")
        if n ~= 0 and card:getNumber() ~= 0 and card:getNumber() >= n then
            return 732
        end
        return 0
    end
}
zhangxingcai:addSkill(shenxian)
zhangxingcai:addSkill(qiangwu)
zhangxingcai:addSkill(qiangwu_mod)
sgs.insertRelatedSkills(extension, qiangwu, qiangwu_mod)
sgs.LoadTranslationTable {
    ["zhangxingcai"] = "张星彩",
    ["&zhangxingcai"] = "张星彩",
    ["#zhangxingcai"] = "敬哀皇后",
    ["~zhangxingcai"] = "复兴汉室之路，臣妾再也不能陪伴左右。",
    ["shenxian"] = "甚贤",
    -- [":shenxian"] = "每当一名其他角色于你的回合外因弃置而失去基本牌后，你可以摸一张牌。",
    [":shenxian"] = "每当一名其他角色在其回合内造成过伤害，你可以摸一张牌。",
    ["$shenxian1"] = "抚慰军心，以安国事。",
    ["$shenxian2"] = "愿尽己力，为君分忧。",
    ["qiangwu"] = "枪舞",
    [":qiangwu"] = "出牌阶段限一次，你可以进行判定：若如此做，本回合，你使用点数小于判定牌点数的【杀】无距离限制，你使用点数大于判定牌点数的【杀】无次数限制且不计入次数限制，你使用点数等于判定牌点数的【杀】同时具备以上两点且伤害+1。",
    ["$qiangwu1"] = "咆哮沙场，万夫不敌！",
    ["$qiangwu2"] = "父亲未竟之业，由我继续！",
    ["$qiangwu_addDamage"] = "%from 执行了“%arg”的效果，%card 伤害值 %arg2"
}
return {extension}

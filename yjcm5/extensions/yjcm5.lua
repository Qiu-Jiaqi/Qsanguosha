extension = sgs.Package("yjcm5", sgs.Package_GeneralPack)
sgs.LoadTranslationTable {
    ["yjcm5"] = "一将成名5"
}
-- 曹叡
caorui = sgs.General(extension, "caorui", "wei", "3", true, true)
-- 恢拓：每当你受到伤害后，你可以令一名角色进行判定，若结果为红色，该角色回复1点体力；若结果为黑色，该角色摸X张牌。（X为此次伤害的伤害值）
huituo =
    sgs.CreateTriggerSkill {
    name = "huituo",
    events = sgs.Damaged,
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName()) then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        local target =
            room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@huituo_target", true, true)
        if target then
            player:showSkill(self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            local judge = sgs.JudgeStruct()
            judge.who = target
            judge.reason = self:objectName()
            room:judge(judge)
            if judge.card:isRed() then
                local recover = sgs.RecoverStruct()
                recover.who = player
                room:recover(target, recover)
            else
                room:drawCards(target, data:toDamage().damage, self:objectName())
            end
            return true
        end
        return false
    end
}
-- 明鉴：出牌阶段限一次，你可以将所有手牌交给一名其他角色，然后该角色下回合的手牌上限+1，且出牌阶段内可以额外使用一张【杀】。
mingjian_card =
    sgs.CreateSkillCard {
    name = "mingjian",
    on_use = function(self, room, source, targets)
        room:obtainCard(
            targets[1],
            source:wholeHandCards(),
            sgs.CardMoveReason(
                sgs.CardMoveReason_S_REASON_GIVE,
                source:objectName(),
                targets[1]:objectName(),
                self:objectName(),
                ""
            ),
            false
        )
        targets[1]:addMark("@mingjian")
    end
}
mingjian_vs =
    sgs.CreateZeroCardViewAsSkill {
    name = "mingjian",
    view_as = function(self, cards)
        local card = mingjian_card:clone()
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#mingjian") and not player:isKongcheng()
    end
}
mingjian =
    sgs.CreateTriggerSkill {
    name = "mingjian",
    events = sgs.EventPhaseStart,
    view_as_skill = mingjian_vs,
    can_trigger = function(self, event, room, player, data)
        if player:getMark("@mingjian") ~= 0 and player:getPhase() == sgs.Player_NotActive then
            -- 明鉴角色回合结束清除明鉴标记
            player:setMark("@mingjian", 0)
        end
        return ""
    end
}
mingjian_maxcard =
    sgs.CreateMaxCardsSkill {
    name = "#mingjian_maxcard",
    extra_func = function(self, player)
        return player:getMark("@mingjian")
    end
}
mingjian_mod =
    sgs.CreateTargetModSkill {
    name = "#mingjian_mod",
    residue_func = function(self, player, card)
        return player:getMark("@mingjian")
    end
}
-- 兴衰：限定技，当你进入濒死状态时可以发动，若此时场上明置角色中每有一名与你势力相同的其他角色存活，
--      你回复1点体力（若体力已满，则增加体力上限后再回复），然后该角色受到1点伤害。
xingshuai =
    sgs.CreateTriggerSkill {
    name = "xingshuai",
    frequency = sgs.Skill_Limited,
    events = sgs.Dying,
    limit_mark = "@xingshuai",
    can_trigger = function(self, event, room, player, data)
        if data:toDying().who:hasSkill(self:objectName()) and player:getMark("@xingshuai") ~= 0 then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            -- 播放限定技动画
            room:doSuperLightbox("caorui", self:objectName())
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        for _, other in sgs.qlist(room:getOtherPlayers(player)) do
            if other:isFriendWith(player) then
                if not player:isWounded() then
                    room:setPlayerProperty(player, "maxhp", player:getMaxHp() + 1)
                    local msg = sgs.LogMessage()
                    msg.type = "$xingshuai_addmaxhp"
                    msg.from = player
                    msg.arg = 1
                    room:sendLog(msg)
                end
                local recover = sgs.RecoverStruct()
                recover.who = player
                room:recover(player, recover)
                room:damage(sgs.DamageStruct(self:objectName(), nil, other, 1, sgs.DamageStruct_Normal))
            end
        end
        room:setPlayerMark(player, "@xingshuai", 0)
        return false
    end
}
caorui:addSkill(huituo)
caorui:addSkill(mingjian)
caorui:addSkill(mingjian_maxcard)
caorui:addSkill(mingjian_mod)
sgs.insertRelatedSkills(extension, mingjian, mingjian_maxcard, mingjian_mod)
caorui:addSkill(xingshuai)
sgs.LoadTranslationTable {
    ["caorui"] = "曹叡",
    ["&caorui"] = "曹叡",
    ["#caorui"] = "天资的明君",
    ["~caorui"] = "悔不该耽于逸乐，致有今日……",
    ["huituo"] = "恢拓",
    [":huituo"] = "每当你受到伤害后，你可以令一名角色进行判定，若结果为红色，该角色回复1点体力；若结果为黑色，该角色摸X张牌。（X为此次伤害的伤害值）",
    ["$huituo1"] = "大展宏图，就在今日！",
    ["$huituo2"] = "复我大魏，扬我国威！",
    ["@huituo_target"] = "你可以发动“恢拓”，选择一名角色。",
    ["mingjian"] = "明鉴",
    [":mingjian"] = "出牌阶段限一次，你可以将所有手牌交给一名其他角色，然后该角色下回合的手牌上限+1，且出牌阶段内可以额外使用一张【杀】。",
    ["$mingjian1"] = "你我推心置腹，岂能相负？",
    ["$mingjian2"] = "孰忠孰奸，朕尚能明辨！",
    ["xingshuai"] = "兴衰",
    [":xingshuai"] = "限定技，当你进入濒死状态时可以发动，若此时场上明置角色中每有一名与你势力相同的其他角色存活，你回复1点体力（若体力已满，则增加体力上限后再回复），然后该角色受到1点伤害。 ",
    ["$xingshuai1"] = "百年兴衰皆由人，不由天！",
    ["$xingshuai2"] = "聚群臣而嘉勋，隆天子之气运！",
    ["$xingshuai_addmaxhp"] = "%from 增加了 %arg 点体力上限"
}
return {extension}

return {
    ["SP"] = "SP",
    --麴义
    ["quyi"] = "麴义",
    ["#quyi"] = "名门的骁将",
    ["illustrator:quyi"] = "秋呆呆",
    ["fuqi"] = "伏骑",
    [":fuqi"] = "锁定技，当你使用牌时，与你距离为1的其他角色不能使用或打出牌响应你使用的牌。",
    ["#fuqi_noResponse"] = "%from 的“%arg”被触发，%to 不能响应【%arg2】",
    ["jiaozi"] = "骄恣",
    [":jiaozi"] = "锁定技，当你造成或受到伤害时，若你的手牌数是全场唯一最多，此伤害值+1。",
    ["#jiaozi_doDamage"] = "%from 的“%arg”被触发，对 %to 的伤害增加为 %arg2 点",
    ["#jiaozi_sufferDamage"] = "%from 的“%arg”被触发，受到的伤害增加为 %arg2 点",
    -- 董白
    ["dongbai"] = "董白",
    ["#dongbai"] = "魔姬",
    ["illustrator:dongbai"] = "Sonia Tang",
    ["lianzhu"] = "连诛",
    [":lianzhu"] = "出牌阶段限一次，你可以展示并交给一名其他角色一张牌，若该牌为：红色，你摸一张牌；黑色，其选择一项：1.你摸两张牌；2.弃置两张牌。",
    ["lianzhu_discard"] = "请弃置两张牌，否则 %src 摸两张牌",
    ["xiahui"] = "黠慧",
    [":xiahui"] = "锁定技，你的黑色牌不占用手牌上限；其他角色获得你的黑色牌时，这些牌标记为“黠慧”牌，其不能使用、打出、弃置“黠慧”牌;其体力值减少时，“黠慧”牌标记消失；其他角色的回合结束时，若其本回合失去过“黠慧”牌，且手牌中没有“黠慧”牌，其失去1点体力。",
    ["#xiahui_limited"] = "%from 的“%arg”被触发，%to 不能使用、打出、弃置从 %from 处获得的标记为“%arg”牌直到其体力值减少为止",
    ["#xiahui_limitedClear"] = "%to 体力值减少，%from 的“%arg”牌标记效果消失",
    ["#xiahui_ignoreBlackHandCards"] = "%from 的“%arg”被触发，黑色牌不计入手牌上限"
}

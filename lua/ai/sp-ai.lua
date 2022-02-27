-- 麴义：伏骑
sgs.ai_skill_invoke.fuqi = function(self, data)
	-- 想进攻或想防御
	return self:willShowForAttack() or self:willShowForDefence()
end
-- 麴义：骄恣
sgs.ai_skill_invoke.jiaozi = function(self, data)
	-- 伤害目标不是友方，并且想进攻
	return not self:isFriend(data:toDamage().to) and self:willShowForAttack()
end

-- 董白：连诛：询问弃牌
sgs.ai_skill_discard.lianzhu = function(self, discard_num, min_num, optional, include_equip)
	local from = self.player:getTag("lianzhu_from"):toPlayer()
	-- 没有来源、来源已死、来源是队友，不弃牌
	if not from or from:isDead() or self:isFriend(from) then
		return {}
	end
	local num = 0
	for _, c in sgs.qlist(self.player:getCards("he")) do
		if self.player:canDiscard(self.player, c:getEffectiveId()) then
			num = num + 1
		end
	end
	-- 弃牌数不足2
	if num < 2 then
		return {}
	end
	-- 自身虚弱
	if self:isWeak() then
		return {}
	end
	return self:askForDiscard("dummyreason", 2, 2, false, true)
end
-- 连诛：发动
-- 插入视为技到ai技能表
local lianzhu_skill = {}
lianzhu_skill.name = "lianzhu"
table.insert(sgs.ai_skills, lianzhu_skill)
-- 获得要使用的牌
lianzhu_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("LianzhuCard") then
		return sgs.Card_Parse("@LianzhuCard=.&lianzhu")
	end
end
-- 如何使用
sgs.ai_skill_use_func.LianzhuCard = function(card, use, self)
	self:sort(self.friends_noself)
	self:sort(self.enemies, "handcard")
	local black, notblack = {}, {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	for _, c in ipairs(cards) do
		if c:isBlack() then
			if not c:isKindOf("Analeptic") then
				table.insert(black, c)
			end
		else
			table.insert(notblack, c)
		end
	end
	if #black > 0 then
		for _, p in ipairs(self.enemies) do
			if self:willShowForAttack() then
				use.card = sgs.Card_Parse("@LianzhuCard=" .. black[1]:getEffectiveId() .. "&lianzhu")
				if use.to then
					use.to:append(p)
				end
				return
			end
		end
	end
	if #notblack > 0 and self:getOverflow() > 0 then
		for _, p in ipairs(self.friends_noself) do
			if self:willShowForDefence() then
				use.card = sgs.Card_Parse("@LianzhuCard=" .. notblack[1]:getEffectiveId() .. "&lianzhu")
				if use.to then
					use.to:append(p)
				end
				return
			end
		end
	end
end
sgs.ai_use_priority.LianzhuCard = 2
sgs.ai_use_value.LianzhuCard = 7
-- 董白：黠慧触发：未亮将时
sgs.ai_skill_invoke.xiahui = function(self, data)
	-- 想进攻或想防御
	return self:willShowForAttack() or self:willShowForDefence()
end

-- 大小乔：星舞
-- 目前只会放牌，现在会动就行-.-
sgs.ai_skill_cardask["@xingwu_card"] = function(self)
	if self.player:isNude() and not self:willShowForAttack() and not self:willShowForDefence() then
		return "."
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	return cards[1]:getEffectiveId()
end

-- 灵雎：竭缘增伤
sgs.ai_skill_cardask["@jieyuan_increase"] = function(self, data)
	if not self:willShowForAttack() or not self:isEnemy(data:toDamage().to) then
		return "."
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if card:isBlack() then
			return card:getEffectiveId()
		end
	end
	return "."
end
sgs.ai_skill_cardask["@jieyuan_increase+"] = function(self, data)
	if not self:willShowForAttack() or not self:isEnemy(data:toDamage().to) then
		return "."
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		return card:getEffectiveId()
	end
	return "."
end
-- 灵雎：竭缘减伤
sgs.ai_skill_cardask["@jieyuan_decrease"] = function(self, data)
	if not self:willShowForDefence() then
		return "."
	end
	local damage = data:toDamage()
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if self:needToLoseHp(self.player, damage.from) and damage.damage <= 1 then
		return "."
	end
	for _, card in ipairs(cards) do
		if card:isRed() then
			return card:getEffectiveId()
		end
	end
	return "."
end
sgs.ai_skill_cardask["@jieyuan_decrease+"] = function(self, data)
	if not self:willShowForDefence() then
		return "."
	end
	local damage = data:toDamage()
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	if self:needToLoseHp(self.player, damage.from) and damage.damage <= 1 then
		return "."
	end
	for _, card in ipairs(cards) do
		return card:getEffectiveId()
	end
	return "."
end
-- 灵雎：焚心亮将询问
sgs.ai_skill_invoke.fenxin = function(self, data)
	-- 想进攻或想防御
	return self:willShowForAttack() or self:willShowForDefence()
end

--星彩：甚贤
sgs.ai_skill_invoke.shenxian = function(self, data)
	-- 想进攻或想防御
	return self:willShowForAttack() or self:willShowForDefence()
end
-- 枪舞
-- local qiangwu_skill = {}
-- qiangwu_skill.name = "qiangwu"
-- table.insert(sgs.ai_skills, qiangwu_skill)
-- qiangwu_skill.getTurnUseCard = function(self)
--     if self.player:hasUsed("qiangwu_card") then
--         return
--     end
--     return sgs.Card_Parse("@qiangwu_card=.")
-- end

-- sgs.ai_skill_use_func.QiangwuCard = function(card, use, self)
--     if self.player:hasUsed("qiangwu_card") then
--         return
--     end
--     use.card = card
-- end
-- sgs.ai_use_value.QiangwuCard = 3
-- sgs.ai_use_priority.QiangwuCard = 11

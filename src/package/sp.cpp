#include "sp.h"

// 麴义
// 伏骑：锁定技，当你使用牌时，与你距离为1的其他角色不能使用或打出牌响应你使用的牌。
class Fuqi : public TriggerSkill {
  public:
    Fuqi() : TriggerSkill("fuqi") {
        events << CardUsed;
        frequency = Compulsory;
    }
    // 记录下与麴义距离为1的角色
    void record(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const {
        CardUseStruct use = data.value<CardUseStruct>();
        // 牌不为技能卡、装备牌、桃、酒
        if (TriggerSkill::triggerable(player) && !use.card->isKindOf("SkillCard") && !use.card->isKindOf("EquipCard") &&
            !use.card->isKindOf("Peach") && !use.card->isKindOf("Analeptic")) {
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *other, room->getOtherPlayers(player)) {
                if (other->distanceTo(player) == 1) {
                    targets << other;
                }
            }
            player->tag["fuqi"] = QVariant::fromValue(targets);
        }
    }
    QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer *&) const {
        CardUseStruct use = data.value<CardUseStruct>();
        QList<ServerPlayer *> targets = player->tag["fuqi"].value<QList<ServerPlayer *>>();
        // 牌不为技能卡、装备牌、桃、酒，技能生效目标不为空
        // QJQ：待优化
        if (TriggerSkill::triggerable(player) && !use.card->isKindOf("SkillCard") && !use.card->isKindOf("EquipCard") &&
            !use.card->isKindOf("Peach") && !use.card->isKindOf("Analeptic") && !targets.isEmpty())
            return QStringList(objectName());
        return QStringList();
    }
    bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer *) const {
        return player->hasShownSkill(this) || player->askForSkillInvoke(this, data);
    }
    bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const {
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(objectName(), player);
        CardUseStruct use = data.value<CardUseStruct>();
        QList<ServerPlayer *> targets = player->tag["fuqi"].value<QList<ServerPlayer *>>();
        player->tag.remove("fuqi");
        LogMessage log;
        log.type = "#fuqi_noResponse";
        log.from = player;
        log.arg = objectName();
        log.arg2 = use.card->objectName();
        log.to = targets;
        room->sendLog(log);
        // 加入到不能响应列表
        foreach (ServerPlayer *target, targets) { use.no_respond_list << target->objectName(); }
        data = QVariant::fromValue(use);
        return false;
    }
};
// 骄恣：锁定技，当你造成或受到伤害时，若你的手牌数是全场唯一最多，此伤害值+1。
class Jiaozi : public TriggerSkill {
  public:
    Jiaozi() : TriggerSkill("jiaozi") {
        events << DamageCaused << DamageInflicted;
        frequency = Compulsory;
    }
    // 记录下此时手牌数是否满足发动技能
    void record(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const {
        if (TriggerSkill::triggerable(player)) {
            player->addMark("jiaozi");
            foreach (ServerPlayer *other, room->getOtherPlayers(player)) {
                if (other->getHandcardNum() >= player->getHandcardNum()) {
                    // 若有一个手牌大于等于麴义则Mark置0，不能发动
                    player->setMark("jiaozi", 0);
                    break;
                }
            }
        }
    }
    QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *&) const {
        if (TriggerSkill::triggerable(player) && player->getMark("jiaozi") > 0) {
            return QStringList(objectName());
        }
        return QStringList();
    }
    bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer *) const {
        return player->hasShownSkill(this) || player->askForSkillInvoke(this, data);
    }
    bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const {
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(objectName(), player);
        DamageStruct damage = data.value<DamageStruct>();
        LogMessage log;
        log.from = player;
        log.arg = objectName();
        if (event == DamageCaused) {
            log.type = "#jiaozi_doDamage";
            log.to << damage.to;
        } else {
            log.type = "#jiaozi_sufferDamage";
        }
        log.arg2 = QString::number(++damage.damage);
        room->sendLog(log);
        data = QVariant::fromValue(damage);
        return false;
    }
};

// 董白
// 连诛：出牌阶段限一次，你可以展示并交给一名其他角色一张牌，若该牌为：红色，你摸一张牌；黑色，其选择一项：1.你摸两张牌；2.弃置两张牌。
// 技能卡部分
LianzhuCard::LianzhuCard() {
    will_throw = false;
    handling_method = Card::MethodNone;
}
void LianzhuCard::onEffect(const CardEffectStruct &effect) const {
    Room *room = effect.from->getRoom();
    int id = getSubcards().first();
    room->showCard(effect.from, id);
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), "lianzhu",
                          QString());
    room->obtainCard(effect.to, this, reason, true);
    // 若为红色，直接摸一张牌，返回
    if (Sanguosha->getCard(id)->isRed()) {
        effect.from->drawCards(1, "lianzhu");
        return;
    }
    // 用于ai：记录技能来源
    effect.to->tag["lianzhu_from"] = QVariant::fromValue(effect.from);
    // 若没有弃牌
    if (!room->askForDiscard(effect.to, "lianzhu", 2, 2, true, true, "lianzhu_discard:" + effect.from->objectName())) {
        effect.from->drawCards(2, "lianzhu");
    }
    effect.to->tag.remove("lianzhu_from");
}
// 视为技部分
class Lianzhu : public OneCardViewAsSkill {
  public:
    Lianzhu() : OneCardViewAsSkill("lianzhu") { filter_pattern = "."; }
    bool isEnabledAtPlay(const Player *player) const { return !player->hasUsed("LianzhuCard"); }
    const Card *viewAs(const Card *originalCard) const {
        LianzhuCard *card = new LianzhuCard;
        card->addSubcard(originalCard);
        card->setSkillName(objectName());
        card->setShowSkill(objectName());
        return card;
    }
};
// 黠慧：锁定技，你的黑色牌不占用手牌上限；其他角色获得你的黑色牌时，这些牌标记为“黠慧”牌，其不能使用、打出、弃置“黠慧”牌;
//      其体力值减少时，“黠慧”牌标记消失；其他角色的回合结束时，若其本回合失去过“黠慧”牌，且手牌中没有“黠慧”牌，其失去1点体力。
class Xiahui : public TriggerSkill {
  public:
    Xiahui() : TriggerSkill("xiahui") {
        events << EventPhaseProceeding << CardsMoveOneTime << PostHpReduced << EventPhaseEnd;
        frequency = Compulsory;
    }
    void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const {
        if (TriggerSkill::triggerable(player)) {
            // 弃牌阶段触发黑色手牌不计入手牌上限
            if (event == EventPhaseProceeding && player->getPhase() == Player::Discard) {
                // 新增函数：获取黑色手牌数
                int blackCardNum = player->getBlackCardNum();
                if (blackCardNum > 0) {
                    // 不计入手牌上限的卡牌数
                    player->addMark("ignoreHandCards_nums", blackCardNum);
                    // 设置黑色牌不能弃置，true代表仅当前一回合；若为false则全局生效，需手动remove
                    room->setPlayerCardLimitation(player, "discard", ".|black", true);
                    // 主要用于未亮将时弃牌阶段主动触发技能
                    player->setFlags("xiahui_ignoreBlackHandCards");
                }
            }
            // “黠慧”牌的移动
            else if (event == CardsMoveOneTime) {
                // QJQ：卡牌移动时结构体真的奇怪，难怪之前张星彩用的有问题，完全不同于教程
                QVariantList move_datas = data.toList();
                foreach (QVariant move_data, move_datas) {
                    CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                    // 黑色牌移动到其他角色处
                    if (move.from && move.from == player &&
                        (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip))) {
                        // 移动来源是董白，且包含来自手牌或装备牌的牌；移动目标存在并活着，且移动到手牌区
                        if (move.to && move.to->isAlive() && move.to_place == Player::PlaceHand) {
                            ServerPlayer *to = (ServerPlayer *)move.to;
                            QVariantList limited = to->tag["xiahui_limited"].toList();
                            // 标记是否触发了设置限制
                            bool flag = false;
                            for (int i = 0; i < move.card_ids.length(); i++) {
                                // 若这张牌不是手牌或装备牌
                                if (move.from_places.at(i) != Player::PlaceHand &&
                                    move.from_places.at(i) != Player::PlaceEquip)
                                    continue;
                                int id = move.card_ids.at(i);
                                // 若不是黑色牌
                                if (!Sanguosha->getCard(id)->isBlack())
                                    continue;
                                limited << id;
                                flag = true;
                                room->setPlayerCardLimitation(to, "use,response,discard", QString::number(id), false);
                            }
                            if (!flag)
                                return;
                            LogMessage log;
                            log.from = player;
                            log.arg = objectName();
                            log.to << to;
                            log.type = "#xiahui_limited";
                            room->sendLog(log);
                            to->tag["xiahui_limited"] = limited;
                        }
                    }
                    // 记录失去“黠慧”牌：其他角色的“黠慧”牌移动到别处
                    else if (move.from && move.from->isAlive() && !move.from->tag["xiahui_limited"].toList().isEmpty()) {
                        // 移动来源存活，且其存在“黠慧”牌，且来自手牌或装备牌
                        if (!move.from_places.contains(Player::PlaceHand) && !move.from_places.contains(Player::PlaceEquip))
                            return;
                        ServerPlayer *from = (ServerPlayer *)move.from;
                        QVariantList limited = from->tag["xiahui_limited"].toList();
                        for (int i = 0; i < move.card_ids.length(); i++) {
                            // 若该牌不是手牌或装备牌
                            if (move.from_places.at(i) != Player::PlaceHand && move.from_places.at(i) != Player::PlaceEquip)
                                continue;
                            // 若该牌不是“黠慧”牌
                            if (!limited.contains(move.card_ids.at(i)))
                                continue;
                            // 只要有一张就可以跳出循环，用Flag而不是Mark，只是本回合
                            from->setFlags("xiahui_lose");
                            // 记录下当前回合的角色
                            room->getCurrent()->setFlags("xiahui_loseTurn");
                            break;
                        }
                    }
                }
            }
        }
        // 先找到董白，董白不是事件的触发者player
        ServerPlayer *dongbai = room->findPlayerBySkillName(objectName());
        // 董白存活有技能，且其他角色回合结束时其有失去“黠慧”牌回合的标记
        if (event == EventPhaseEnd && TriggerSkill::triggerable(dongbai) && player->getPhase() == Player::Finish &&
            player != dongbai && player->hasFlag("xiahui_loseTurn")) {
            foreach (ServerPlayer *loser, room->getAlivePlayers()) {
                if (loser->hasFlag("xiahui_lose")) {
                    QVariantList limited = loser->tag["xiahui_limited"].toList();
                    foreach (int id, loser->handCards()) {
                        // 若有“黠慧”牌，则不需失去体力
                        if (limited.contains(id)) {
                            return;
                        }
                    }
                    room->sendCompulsoryTriggerLog(dongbai, objectName());
                    room->loseHp(loser);
                }
            }
        }
        // 以上效果是董白存活时触发，而Hp减少是remove“黠慧”牌的限制，此时董白可能已死或失去技能
        if (event == PostHpReduced && !player->tag["xiahui_limited"].toList().isEmpty()) {
            foreach (QVariant id, player->tag["xiahui_limited"].toList()) {
                // 解除限制
                room->removePlayerCardLimitation(player, "use,response,discard", QString::number(id.value<int>()) + "$0");
            }
            player->tag.remove("xiahui_limited");
            LogMessage log;
            log.from = dongbai;
            log.arg = objectName();
            log.to << player;
            log.type = "#xiahui_limitedClear";
            room->sendLog(log);
        }
    }
    QStringList triggerable(TriggerEvent event, Room *, ServerPlayer *player, QVariant &, ServerPlayer *&) const {
        // 只是用来触发未亮将时黑色手牌不计入手牌上限的询问以及提示信息
        if (TriggerSkill::triggerable(player)) {
            if (event == EventPhaseProceeding && player->getPhase() == Player::Discard &&
                player->hasFlag("xiahui_ignoreBlackHandCards")) {
                return QStringList(objectName());
            }
        }
        return QStringList();
    }
    bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer *) const {
        return player->hasShownSkill(this) || player->askForSkillInvoke(this, data);
    }
    bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const {
        room->notifySkillInvoked(player, objectName());
        LogMessage log;
        log.from = player;
        log.arg = objectName();
        log.type = "#xiahui_ignoreBlackHandCards";
        room->sendLog(log);
        return false;
    }
};

SPPackage::SPPackage() : Package("SP") {
    // 麴义
    General *quyi = new General(this, "quyi", "qun", 4);
    quyi->addSkill(new Fuqi);
    quyi->addSkill(new Jiaozi);

    // 董白
    General *dongbai = new General(this, "dongbai", "qun", 3, false);
    dongbai->addSkill(new Lianzhu);
    addMetaObject<LianzhuCard>();
    dongbai->addSkill(new Xiahui);
}

ADD_PACKAGE(SP)
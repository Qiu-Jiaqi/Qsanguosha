#ifndef _SP_H
#define _SP_H

#include "client.h" // 使用Self引用头文件
#include "engine.h" // 使用Sanguosha引用头文件
#include "general.h"
#include "package.h"
#include "skill.h"
#include "standard-wu-generals.h" // 大小乔技能

class SPPackage : public Package {
    Q_OBJECT
  public:
    SPPackage();
};
// 连诛
class LianzhuCard : public SkillCard {
    Q_OBJECT
  public:
    Q_INVOKABLE LianzhuCard();
    void onEffect(const CardEffectStruct &effect) const;
};
// 星舞
class XingwuCard : public SkillCard {
    Q_OBJECT
  public:
    Q_INVOKABLE XingwuCard();
    void onEffect(const CardEffectStruct &effect) const;
};
#endif
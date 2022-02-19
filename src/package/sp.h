#ifndef _SP_H
#define _SP_H

#include "engine.h"
#include "general.h"
#include "package.h"
#include "skill.h"

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

  private:
};
#endif
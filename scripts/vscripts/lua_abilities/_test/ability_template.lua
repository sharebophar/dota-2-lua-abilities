-- 技能事件模板
ability_template = class({})

----------------------------------------------------常用事件

-- 技能效果开始
-- Cast time finished, spell effects begin.
ability_template:OnSpellStart()
{

}

-- 开关技能
-- Ability is toggled on/off.
ability_template:OnToggle()
{

}

-- 吟唱结束 upgradeAbility: handle
ability_template:OnChannelFinish(interrupted)
{

}

-- 吟唱进行中 interval: float
ability_template:OnChannelThink(interval)
{

}

-- 与OnProjectileHit相同，但可以传递自定义数据，参数 target: CDOTA_BaseNPC | nil, location: Vector, extraData: table): bool | nil
ability_template:OnProjectileHit_ExtraData(target, location, extraData)
{
    return true
}

-- 与 OnProjectileThink 相同，但可以传递自定义数据，参数 location: Vector, extraData: table
ability_template:OnProjectileThink_ExtraData(location, extraData)
{

}

-------------------------------------------------------不常用事件 之 较常用
-- 技能提升等级时
ability_template:OnUpgrade()
{

}

-- Cast time did not complete successfully.
-- 技能中断
ability_template:OnAbilityPhaseInterrupted()
{

}

-- 技能阶段开始，技能执行成功后返回true.  Cast time begins (return true for successful cast).
ability_template:OnAbilityPhaseStart()
{
    return true
}

---------------------------------------------------------不常用事件 之 英雄相关

-- A hero has died in the vicinity (ie Urn), takes table of params.
-- 有英雄在附近死亡时，参数 unit: CDOTA_BaseNPC, attacker: CDOTA_BaseNPC, event: table
ability_template:OnHeroDiedNearby(unit, attacker, event)
{

}

-- 英雄升级时
ability_template:OnHeroLevelUp()
{

}

-- 拥有者死亡时
ability_template:OnOwnerDied()
{

}

-- 英雄出生或重生时
ability_template:OnOwnerSpawned()
{

}

-------------------------------------------------------不常用事件 之 选择性使用

-- 子弹碰撞时，子弹被检测到与指定目标发生碰撞或到达目标地点时触发，当返回true时，子弹会被销毁，参数 target: CDOTA_BaseNPC | nil, location: Vector): bool | nil
-- Projectile has collided with a given target or reached its destination. If 'true` is returned, projectile would be destroyed.
ability_template:OnProjectileHit(target, location)
{
    return true
}

-- 与OnProjectileHit相同，但可以传递 子弹句柄，参数 target: CDOTA_BaseNPC | nil, location: Vector, projectileHandle: ProjectileID): bool | nil
ability_template:OnProjectileHitHandle(target, location, projectileHandle)
{

}

-- 子弹移动中思考，参数 location: Vector
ability_template:OnProjectileThink(location)
{

}

-- 与 OnProjectileThink 相同，但可以传递子弹句柄，参数 projectileHandle: ProjectileID
ability_template:OnProjectileThinkHandle(projectileHandle)
{

}

---------------------------------------------------- 不常用事件 之 罕见
-- 技能被窃取时，参数 sourceAbility: CDOTABaseAbility
-- Special behavior when stolen by Spell Steal.
ability_template:OnStolen(sourceAbility)
{

}

-- 技能被遗忘时
-- Special behavior when lost by Spell Steal.
ability_template:OnUnStolen()
{

}

-- Caster (hero only) gained a level, skilled an ability, or received a new stat bonus.
-- 英雄升级，习得技能或获得新的状态时触发
ability_template:OnHeroCalculateStatBonus()
{

}

----------------------------------------- 不常用事件 之 背包事件
-- 背包内容发生改变
ability_template:OnInventoryContentsChanged()
{

}

-- 物品装备时，参数 item: CDOTA_Item
ability_template:OnItemEquipped(item)
{

}

-----------------------------------------意义不明的事件，谨慎使用
-- The ability was pinged. Ctrl + Q 技能升级吗？意义不明
-- 参数 playerId: PlayerID, ctrlHeld: bool
ability_template:OnAbilityPinged(playerId, ctrlHeld)
{

}

-- 技能升级，参数 upgradeAbility: handle，官方无描述
ability_template:OnAbilityUpgrade(upgradeAbility)
{

}
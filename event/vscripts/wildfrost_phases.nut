//credit to lobotomy and for letting me use their code :'D i wanted to kms when modifying this

PrecacheModel("models/props_mvm/indicator/indicator_circle_long.mdl")

::WildFrost <- {
	divider_death_origin = Vector()

	// provide a script handle reference to worldspawn, for convenience.
	hWorldspawn = FindByName(null, "worldspawn")
}
WildFrost.DisplayIndicatorCircle <- function(ent, scale, duration, follow_ent, is_yellow = false)

	{
		local indicator = SpawnEntityFromTable("prop_dynamic",
		{
			model = "models/props_mvm/indicator/indicator_circle_long.mdl" // radius = 16 hu
			origin = ent.GetOrigin()
			DefaultAnim = "start"
			skin = is_yellow ? 2 : 1
			solid = 0
			modelscale = scale
			disablereceiveshadows = true
			disableshadows = true
		})

		if (follow_ent)
		{
			indicator.ValidateScriptScope()
			local scope = indicator.GetScriptScope()
			scope.FollowEntity <- function()
			{
				self.SetLocalOrigin(ent.GetOrigin())
			}
			PopExtUtil.AddThinkToEnt(indicator, "FollowEntity")
		}

		EntFireByHandle(indicator, "SetAnimation", "end", duration, null, null)
		EntFireByHandle(indicator, "SetDefaultAnimation", "end", duration, null, null) // do i need this? idk it just works
		EntFireByHandle(indicator, "Kill", null, duration + 0.8, null, null)
	}
PopExt.AddRobotTag("Phase1",
{


	OnSpawn = function(bot, tag)
	{

		local scope = bot.GetScriptScope()

		scope.is_resisting_damage <- false

		scope.SplitThink <- function()
		{
			if (bot.GetHealth() > bot.GetMaxHealth() * 0.2) return

			bot.AddCondEx(TF_COND_MVM_BOT_STUN_RADIOWAVE, 99, null)
			WildFrost.DisplayIndicatorCircle(bot, 5.65, 3, true)
			is_resisting_damage = true

			EntFireByHandle(bot, "RunScriptCode", @"
				local origin = self.GetOrigin()

				DispatchParticleEffect(`drg_wrenchmotron_teleport`, origin, Vector())
				DispatchParticleEffect(`drg_wrenchmotron_impact`, origin, Vector())

				for (local player; player = FindByClassnameWithin(player, `player`, origin, 200);)
				{
					if (player.GetTeam() != TF_TEAM_PVE_DEFENDERS) continue
					player.TakeDamage(9999, DMG_MELEE, self)
				}
				for (local building; building = FindByClassnameWithin(building, `obj_*`, origin, 200);)
				{
					if (building.GetTeam() != TF_TEAM_PVE_DEFENDERS) continue
					building.TakeDamage(9999, DMG_MELEE, self)
				}

				WildFrost.divider_death_origin = origin
				self.TakeDamage(99999999, DMG_MELEE, WildFrost.hWorldspawn)
			", 3, null, null)

			delete PlayerThinkTable.SplitThink
		}
		PopExtUtil.AddThinkToEnt(bot, "SplitThink")
	}

	OnTakeDamage = function(bot, params)
	{
		if (bot.GetScriptScope().is_resisting_damage) params.damage *= 0.2
	}
})

PopExt.AddRobotTag("Phase2components",
{
	OnSpawn = function(bot, tag)
	{
		if (bot.HasBotTag("Phase2teleportfirst"))
			bot.SetAbsOrigin(WildFrost.divider_death_origin)
		else
			EntFireByHandle(bot, "RunScriptCode", "self.SetAbsOrigin(WildFrost.divider_death_origin)", 3*SINGLE_TICK, null, null)
	}
})

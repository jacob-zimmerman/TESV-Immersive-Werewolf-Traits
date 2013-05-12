scriptname ImmersiveWerewolfTraits_MASTER extends Quest
import Utility
import Math

Actor Property PlayerRef Auto
Spell Property WerewolfChangeRingOfHircine Auto ; the form ID for the power given when the player equips the ring of hircine
Spell Property WerewolfChange Auto ; the form ID for the Beast Form power
float dawn = 19.0 ; moon appears in sky at 7 pm
float dusk = 5.0; moon leaves the sky at 5 am
float updateInterval = 60.0 ; registers for updates every 60 seconds
GlobalVariable Property GameHour Auto
Faction Property PlayerWerewolfFaction Auto

float speedMultiplier ; during a full moon, the character's normal running speed is multiplied by this
float jumpMultiplier ; during a full moon, the character's normal jumping height is multiplied by this
float attackDamageMultiplier ; during a full moon, the character's non-magic attack damage multiplier is multiplied by this
float weaponSpeedMultiplier ; during a full moon, the character's normal attack speed is multiplied by this
float healRateMultiplier ; during a full moon, the character's health regen speed is multiplied by this
float staminaRateMultiplier ; during a full moon, the character's stamina regen speed is multiplied by this
float beastMultiplier ; during a full moon, the character's chance of forcibly turning into a werewolf

bool enableSpeedAugment ; if true, normal running speed is augmented by moon bonus
bool enableJumpAugment ; if true, normal jumping height is augmented by moon bonus
bool enableAttackDamageAugment ; if true, non-magic attack damage is augmented by moon bonus
bool enableWeaponSpeedAugment ; if true, attack speed is augmented by moon bonus
bool enableHealRateAugment ; if true, health regen is augmented by moon bonus
bool enableStaminaRateAugment ; if true, stamina regen is augmented by moon bonus
bool enableForcedChange ; if true, the player may randomly turn into a werewolf at night
bool enableHircineOverride ; if true, the Ring of Hircine prevents random transformations when worn

bool hasChanged ; if true, the player has already changed during this night
bool ignoreLycanthropy ; if true, mod still affects player, even if he does not have lycanthropy
bool isWerewolf ; if true, player is a werewolf

;===================================================================================
;
;  Starts 
;
;===================================================================================
Event OnInit()
	isWerewolf = playerIsWerewolf()
	toggleChangesIfApplicable()
	RegisterForSingleUpdate(updateInterval)
endEvent

;===================================================================================
;
;	Starts loop that checks whether or not it is nighttime (to augment stats/force
;	werewolf transformation. Polls for updates every updateInterval seconds
;
;===================================================================================
Event OnUpdate()
	toggleChangesIfApplicable()
	RegisterForSingleUpdate(updateInterval)
endEvent

Function toggleChangesIfApplicable()
	if (isNighttime())
		if (!hasChanged)
			forceTransformation()
			augmentStats()
			hasChanged = true
		endIf
	else
		hasChanged = false
	endIf
endFunction


 
;===================================================================================
;
;	GetPassedGameDays() returns the number of fully passed ingame days as an integer.
;
;===================================================================================
 
int Function GetPassedGameDays() Global
	float gameTime
	int gameDaysPassed
 
	gameTime = GetCurrentGameTime()
	gameDaysPassed = gameTime as int
	return gameDaysPassed
endFunction

;===================================================================================
;
;	GetPassedGameHours() returns the number of passed ingame hours of the current day
;	as an integer.
;
;===================================================================================
 
int Function GetPassedGameHours() Global
	float gameTime
	int gameHoursPassed
 
	gameTime = GetCurrentGameTime()
	gameHoursPassed = ((gameTime - (gameTime as int)) * 24) as int
	return gameHoursPassed
endFunction
 
;===================================================================================
;
;	GetMoonModifier() returns a float value based on the percentage of the moon that
;	is currently visible.
;
;	The returncodes are as follows:
;		1.0 - 	Full Moon
;		0.75 - 	Waxing/Waning 3/4 Moon
;		0.5 -		Waxing/Waning 1/2 Moon
;		0.25 -	Waxing/Waning 1/4 Moon
;		0 - 		New Moon
;
;===================================================================================
 
float Function GetMoonModifier() Global
	int gameDaysPassed
	int gameHoursPassed
	int phaseTest
	gameDaysPassed = GetPassedGameDays()
	gameHoursPassed = GetPassedGameHours()
 
	if (gameHoursPassed >= 12.0)
		gameDaysPassed += 1
	endIf
 
	phaseTest = gameDaysPassed % 24 ; a full cycle through the moon phases lasts 24 days
	if phaseTest >= 22 || phaseTest == 0
		return 0.75
	elseIf phaseTest < 4
		return 1.0
	elseIf phaseTest < 7
		return 0.75
	elseIf phaseTest < 10
		return 0.5
	elseIF phaseTest < 13
		return 0.25
	elseIf phaseTest < 16
		return 0.0
	elseIf phaseTest < 19
		return 0.25
	elseIf phaseTest < 22
		return 0.75
	endIf

endFunction

;===================================================================================
;
;	Returns true if the player is a werewolf -- false otherwise
;
;===================================================================================
bool Function playerIsWerewolf()

	if (PlayerRef.IsInFaction(PlayerWerewolfFaction) && PlayerRef.HasSpell(WerewolfChange))
		Debug.Trace("Player is a werewolf.")
		return true
	else
		Debug.Trace("Player is not a werewolf.")
		return false
	endIf

endFunction

;===================================================================================
;
;	Returns true if it is currently nighttime (between dawn and dusk)
;
;===================================================================================
bool function isNighttime()
	float time = GameHour.GetValue()
	if ((time > dusk) && (time < dawn))
		return true
	else
		return false
	endIf
endFunction

;===================================================================================
;
;	Returns true if the player has the uncursed Ring of Hircine equipped
;
;===================================================================================
bool function hasRingEquipped()
	if (PlayerRef.HasSpell(WerewolfChangeRingOfHircine))
		return true
	else
		return false
	endIf
endFunction

;===================================================================================
;
;	Augments actor values based on the current phase of the moon and whether or not
;	they have these augmentations enabled
;
;===================================================================================
function augmentStats()

	float baseSpeedMult = PlayerRef.GetActorValue("SpeedMult")
	float baseJumpBonus = PlayerRef.GetActorValue("JumpBonus")
	float baseAttackDamageMult = PlayerRef.GetActorValue("attackDamageMult")
	float baseWeaponSpeedMult = PlayerRef.GetActorValue("WeaponSpeedMult")
	float baseHealRate = PlayerRef.GetActorValue("HealRate")
	float baseStaminaRate = PlayerRef.GetActorValue("StaminaRate")
	float moonModifier = GetMoonModifier()


	if (enableSpeedAugment)
		PlayerRef.ModActorValue("SpeedMult", baseSpeedMult * speedMultiplier * moonModifier)
	endIf
	if (enableJumpAugment)
		PlayerRef.ModActorValue("JumpBonus", baseJumpBonus * jumpMultiplier * moonModifier)
	endIf
	if (enableAttackDamageAugment)
		PlayerRef.ModActorValue("attackDamageMult", baseAttackDamageMult * attackDamageMultiplier * moonModifier)
	endIf
	if (enableWeaponSpeedAugment)
		PlayerRef.ModActorValue("WeaponSpeedMultiplier", baseWeaponSpeedMult * weaponSpeedMultiplier * moonModifier)
	endIf
	if (enableHealRateAugment)
		PlayerRef.ModActorValue("HealRate", baseHealRate * healRateMultiplier * moonModifier)
	endIf
	if (enableStaminaRateAugment)
		PlayerRef.ModActorValue("StaminaRate", baseStaminaRate * staminaRateMultiplier * moonModifier)
	endIf

endFunction

;===================================================================================
;
;	Forces a werewolf transformation if possible (must pass probability check and 
;	fail the Hircine Ring Override)
;
;===================================================================================
function forceTransformation()
	if (enableHircineOverride && hasRingEquipped())
		return ; no transformation enabled
	else
		float random = Utility.RandomFloat()
		if (beastMultiplier * GetMoonModifier() > random)
			WerewolfChangeRingOfHircine.Cast(PlayerRef)
			;WerewolfChange.Cast(PlayerRef)
		endIf
	endIf
endFunction

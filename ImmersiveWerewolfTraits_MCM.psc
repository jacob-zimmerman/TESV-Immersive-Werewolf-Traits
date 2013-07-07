;===================================================================================
; IMMERSIVE WEREWOLF TRAITS
;
; VERSION 0.5 (Not yet finished)
;
; AUTHOR: Jacob Lloyd Zimmerman
;
; DESCRIPTION: A mod that aims to provide a more immersive experience when playing
; as a werewolf. This mod accomplishes this through the following:

;  	1) Random, uncontrollable transformations that vary with the moon phases --
;			the player is more likely to randomly transform into a werewolf the more
;			full the moon is
;		2) Passive bonuses that increase with the intensity of the moon -- the more
;			full the moon, the greater the stat boost. Allows stat boosts to movement
;			speed, jump height, attack damage, weapon speed, health recovery rate,
;			and stamina recovery rate.
;		3) Allows Ring of Hircine to prevent these random transformations
;		4) Allows the player to customize all of these features and fine tune them
;			to fit their own play style for maximum immersion.
;
; PLANS FOR FUTURE VERSIONS: If there are any other stat boosts that people would
; like for me to add, I would be more than happy to make changes to this mod to
; suit their needs. Additionally, I may combine the functionality of my Friendlier
; Wolves Mod with this since they seem to be a good fit for each other.
;
; IMPORTANT NOTE: This mod requires SkyUI and its Mod Configuration Menu to work
; properly. Otherwise, the user will not be able to adjust any of the values.
;
;===================================================================================
scriptname ImmersiveWerewolfTraits_MCM extends SKI_ConfigBase

import Math
import Utility

;========================== SCRIPT VERSION ==========================

int function GetVersion()
	return 1 ; Default version
endFunction


;========================== PRIVATE VARIABLES ==========================

; OIDs (T:Text B:Toggle S:Slider M:Menu, C:Color, K:Key)
int playerIsWerewolf_OID_T
int ignoreLycanthropy_OID_T
int currentMoonVisibility_OID_T

int enableForcedChange_OID_T
int enableSpeedAugment_OID_T
int enableJumpAugment_OID_T
int enableAttackDamageAugment_OID_T
int enableWeaponSpeedAugment_OID_T
int enableHealRateAugment_OID_T
int enableStaminaRateAugment_OID_T

int speedMultiplier_OID_T
int jumpMultiplier_OID_T
int attackDamageMultiplier_OID_T
int weaponSpeedMultiplier_OID_T
int healRateMultiplier_OID_T
int staminaRateMultiplier_OID_T

int alwaysChange_OID_T
int enableHircineOverride_OID_T
int beastMultiplier_OID_T

int ignoreLycanthropy_OID_B

int enableForcedChange_OID_B
int enableSpeedAugment_OID_B
int enableJumpAugment_OID_B
int enableAttackDamageAugment_OID_B
int enableWeaponSpeedAugment_OID_B
int enableHealRateAugment_OID_B
int enableStaminaRateAugment_OID_B

int speedMultiplier_OID_S
int jumpMultiplier_OID_S
int attackDamageMultiplier_OID_S
int weaponSpeedMultiplier_OID_S
int healRateMultiplier_OID_S
int staminaRateMultiplier_OID_S

int alwaysChange_OID_B
int enableHircineOverride_OID_B
int beastMultiplier_OID_S

int isAugmented_OID_T

int restoreDefaults_OID_T



; State

; ...

; Internal
Actor Property PlayerRef Auto
Spell Property WerewolfChangeRingOfHircine Auto ; the form ID for the power given when the player equips the ring of hircine
Spell Property WerewolfChange Auto ; the form ID for the Beast Form power
float dawn = 19.0 ; moon appears in sky at 7 pm
float dusk = 5.0; moon leaves the sky at 5 am
float updateInterval = 30.0 ; registers for updates every 30 seconds
GlobalVariable Property GameHour Auto
Faction Property PlayerWerewolfFaction Auto

float speedMultiplier ; during a full moon, the character's normal running speed is multiplied by this
float jumpMultiplier ; during a full moon, the character's normal jumping height is multiplied by this
float attackDamageMultiplier ; during a full moon, the character's non-magic attack damage multiplier is multiplied by this
float weaponSpeedMultiplier ; during a full moon, the character's normal attack speed is multiplied by this
float healRateMultiplier ; during a full moon, the character's health regen speed is multiplied by this
float staminaRateMultiplier ; during a full moon, the character's stamina regen speed is multiplied by this
float beastMultiplier ; during a full moon, the character's chance of forcibly turning into a werewolf

float speedBonus ; bonus applied to character's running speed
float jumpBonus ; bonus applied to the character's normal jumping height
float attackDamageBonus ; bonus applied to the character's non-magic attack damage multiplier
float weaponSpeedBonus ; bonus applied to the character's normal attack speed
float healRateBonus ; bonus applied to the character's health regen speed
float staminaRateBonus ; bonus applied to the character's stamina regen speed

bool enableSpeedAugment ; if true, normal running speed is augmented by moon bonus
bool enableJumpAugment ; if true, normal jumping height is augmented by moon bonus
bool enableAttackDamageAugment ; if true, non-magic attack damage is augmented by moon bonus
bool enableWeaponSpeedAugment ; if true, attack speed is augmented by moon bonus
bool enableHealRateAugment ; if true, health regen is augmented by moon bonus
bool enableStaminaRateAugment ; if true, stamina regen is augmented by moon bonus

float lastChangeTime ; the time the last transformation/augmentation was attempted

bool enableForcedChange ; if true, the player may randomly turn into a werewolf at night
bool alwaysChange ; if true, random transformations occur every night
bool enableHircineOverride ; if true, the Ring of Hircine prevents random transformations when worn

bool hasChanged ; if true, the player has already changed during this night
bool isAugmented ; if true, the player's stats have already been augmented
bool ignoreLycanthropy ; if true, mod still affects player, even if he does not have lycanthropy
bool isWerewolf ; if true, player is a werewolf
; ...


;========================== INITIALIZATION ==========================

; @implements SKI_ConfigBase
event OnConfigInit()
{Called when this config menu is initialized}

	Pages = new string[2]
	Pages[0] = "Current Settings"
	Pages[1] = "Adjust Settings"

	isWerewolf = playerIsWerewolf()
	hasChanged = false
	isAugmented = false
	ignoreLycanthropy = false
	alwaysChange = false
	enableForcedChange = true
	enableHircineOverride = true
	lastChangeTime = -11.0

	enableSpeedAugment = true
	enableJumpAugment = true
	enableAttackDamageAugment = true
	enableWeaponSpeedAugment = true
	enableHealRateAugment = true
	enableStaminaRateAugment = true

	speedMultiplier = 2.0
	jumpMultiplier = 2.0
	attackDamageMultiplier = 2.0
	weaponSpeedMultiplier = 2.0
	healRateMultiplier = 2.0
	staminaRateMultiplier = 2.0
	beastMultiplier = 1.0

	toggleChangesIfApplicable()
	RegisterForSingleUpdate(updateInterval)
; ...
endEvent

; @implements SKI_QuestBase
event OnVersionUpdate(int a_version)
{Called when a version update of this script has been detected}

; ...
endEvent


;========================== EVENTS ==========================

; @implements SKI_ConfigBase
event OnPageReset(string a_page)
{Called when a new page is selected, including the initial empty page}
	if (a_page == "Current Settings")

		SetCursorFillMode(TOP_TO_BOTTOM)
		SetCursorPosition(0)

		AddHeaderOption("Player Status")
		
		if (isWerewolf)
			playerIsWerewolf_OID_T = AddTextOption("PlayerIsWerewolf: ", "True")
		else
			playerIsWerewolf_OID_T = AddTextOption("PlayerIsWerewolf: ", "False")
		endIf

		if (isAugmented)
			isAugmented_OID_T = AddTextOption("IsAugmented: ", "True")
		else
			isAugmented_OID_T = AddTextOption("IsAugmented: ", "False")
		endIf

		String temp = ((GetMoonModifier() * 100) as int) as String
		temp = temp + "%"
		currentMoonVisibility_OID_T = AddTextOption("Current Moon Visibility: ", temp)
		AddEmptyOption()

		AddHeaderOption("Mod Settings")

		if (enableSpeedAugment)
			enableSpeedAugment_OID_T = AddTextOption("Enable Speed Augment: ", "True")
		else
			enableSpeedAugment_OID_T = AddTextOption("Enable Speed Augment: ", "False")
		endIf

		if (enableJumpAugment)
			enableJumpAugment_OID_T = AddTextOption("Enable Jump Augment: ", "True")
		else
			enableJumpAugment_OID_T = AddTextOption("Enable Jump Augment: ", "False")
		endIf

		if (enableAttackDamageAugment)
			enableAttackDamageAugment_OID_T = AddTextOption("Enable Attack Damage Augment: ", "True")
		else
			enableAttackDamageAugment_OID_T = AddTextOption("Enable Attack Damage Augment: ", "False")
		endIf

		if (enableWeaponSpeedAugment)
			enableWeaponSpeedAugment_OID_T = AddTextOption("Enable Weapon Speed Augment: ", "True")
		else
			enableWeaponSpeedAugment_OID_T = AddTextOption("Enable Weapon Speed Augment: ", "False")
		endIf

		if (enableHealRateAugment)
			enableHealRateAugment_OID_T = AddTextOption("Enable Heal Rate Augment: ", "True")
		else
			enableHealRateAugment_OID_T = AddTextOption("Enable Heal Rate Augment: ", "False")
		endIf

		if (enableStaminaRateAugment)
			enableStaminaRateAugment_OID_T = AddTextOption("Enable Stamina Rate Augment: ", "True")
		else
			enableStaminaRateAugment_OID_T = AddTextOption("Enable Stamina Rate Augment: ", "False")
		endIf

		AddEmptyOption()

		if (ignoreLycanthropy)
			ignoreLycanthropy_OID_T = AddTextOption("Ignore Lycanthropy: ", "True")
		else
			ignoreLycanthropy_OID_T = AddTextOption("Ignore Lycanthropy: ", "False")
		endIf

		AddEmptyOption()

		AddHeaderOption("Transformation Settings")
		if (enableForcedChange)
			enableForcedChange_OID_T = AddTextOption("Enable Forced Change", "True")
		else
			enableForcedChange_OID_T = AddTextOption("Enable Forced Change", "False")
		endIf

		if (alwaysChange)
			alwaysChange_OID_T = AddTextOption("Always Change: ", "True")
		else
			alwaysChange_OID_T = AddTextOption("Always Change: ", "False")
		endIf

		if (enableHircineOverride)
			enableHircineOverride_OID_T = AddTextOption("Enable Hircine Override: ", "True")
		else
			enableHircineOverride_OID_T = AddTextOption("Enable Hircine Override: ", "False")
		endIf

		temp = (beastMultiplier as String) + "x"
		beastMultiplier_OID_T = AddTextOption("Beast Multiplier: ", temp)

		AddEmptyOption()

		AddHeaderOption("Augment Settings")

		temp = (speedMultiplier as String) + "x"
		speedMultiplier_OID_T = AddTextOption("Speed Multiplier: ", temp)

		temp = (jumpMultiplier as String) + "x"
		jumpMultiplier_OID_T = AddTextOption("Jump Multiplier: ", temp)

		temp = (attackDamageMultiplier as String) + "x"
		attackDamageMultiplier_OID_T = AddTextOption("Attack Damage Multiplier: ", temp)

		temp = (weaponSpeedMultiplier as String) + "x"
		weaponSpeedMultiplier_OID_T = AddTextOption("Weapon Speed Multiplier: ", temp)

		temp = (healRateMultiplier as String) + "x"
		healRateMultiplier_OID_T = AddTextOption("Heal Rate Multiplier: ", temp)

		temp = (staminaRateMultiplier as String) + "x"
		staminaRateMultiplier_OID_T = AddTextOption("Stamina Rate Multiplier: ", temp)

	endIf

	if (a_page == "Adjust Settings")

		SetCursorFillMode(TOP_TO_BOTTOM)
		SetCursorPosition(0)

		AddHeaderOption("Mod Settings")

		enableSpeedAugment_OID_B = AddToggleOption("Enable Speed Augment", enableSpeedAugment)
		enableJumpAugment_OID_B = AddToggleOption("Enable Jump Augment", enableJumpAugment)
		enableAttackDamageAugment_OID_B = AddToggleOption("Enable Attack Damage Augment", enableAttackDamageAugment)
		enableWeaponSpeedAugment_OID_B = AddToggleOption("Enable Weapon Speed Augment", enableWeaponSpeedAugment)
		enableHealRateAugment_OID_B = AddToggleOption("Enable Heal Rate Augment", enableHealRateAugment)
		enableStaminaRateAugment_OID_B = AddToggleOption("Enable Stamina Rate Augment", enableStaminaRateAugment)

		AddEmptyOption()
		ignoreLycanthropy_OID_B = AddToggleOption("Ignore Lycanthropy", ignoreLycanthropy)
		AddEmptyOption()


		AddHeaderOption("Transformation Settings")
		enableForcedChange_OID_B = AddToggleOption("Enable Forced Change", enableForcedChange)
		alwaysChange_OID_B = AddToggleOption("Always Change", alwaysChange)
		enableHircineOverride_OID_B = AddToggleOption("Enable Hircine Override", enableHircineOverride)
		beastMultiplier_OID_S = AddSliderOption("Beast Multiplier", beastMultiplier, "{1}")

		AddEmptyOption()


		AddHeaderOption("Augment Settings")
		speedMultiplier_OID_S = AddSliderOption("Speed Multiplier", speedMultiplier, "{1}")
		jumpMultiplier_OID_S = AddSliderOption("Jump Multiplier", jumpMultiplier, "{1}")
		attackDamageMultiplier_OID_S = AddSliderOption("Attack Damage Multiplier", attackDamageMultiplier, "{1}")
		weaponSpeedMultiplier_OID_S = AddSliderOption("Weapon Speed Multiplier", weaponSpeedMultiplier, "{1}")
		healRateMultiplier_OID_S = AddSliderOption("Heal Rate Multiplier", healRateMultiplier, "{1}")
		staminaRateMultiplier_OID_S = AddSliderOption("Stamina Rate Multiplier", staminaRateMultiplier, "{1}")

		AddEmptyOption()
		AddHeaderOption("Other Settings")
		restoreDefaults_OID_T = AddTextOption("Restore Defaults", "")
		
	endIf
; ...
endEvent

; @implements SKI_ConfigBase
event OnOptionHighlight(int a_option)
{Called when highlighting an option}
	if (a_option == playerIsWerewolf_OID_T)
		SetInfoText("Displays whether or not the player is a werewolf. True if the player is a werewolf; false otherwise.")
	elseIf (a_option == ignoreLycanthropy_OID_T || a_option == ignoreLycanthropy_OID_B)
		SetInfoText("If true, mod still affects player, even if he does not have lycanthropy.\nDefault: false")
	elseIf (a_option == currentMoonVisibility_OID_T)
		SetInfoText("The current percentage of the moon that is visible. E.g., if it is a full moon, this number will be 100%, but during a waxing or waning half moon, it will only be 50%")

	elseIf (a_option == enableForcedChange_OID_T || a_option == ignoreLycanthropy_OID_B)
		SetInfoText("If true, the player may randomly turn into a werewolf at night.\nDefault: true")
	elseIf (a_option == enableSpeedAugment_OID_T || a_option == enableSpeedAugment_OID_B)
		SetInfoText("If true, normal running speed is augmented based on speed multiplier and moon visibility.\nDefault: true")
	elseIf (a_option == enableJumpAugment_OID_T || a_option == enableJumpAugment_OID_B)
		SetInfoText("If true, normal jumping height ise augmented based on jump multiplier and moon visibility.\nDefault: true")
	elseIf (a_option == enableAttackDamageAugment_OID_T || a_option == enableAttackDamageAugment_OID_B)
		SetInfoText("If true, non-magic attack damage is augmented based on attack damage multiplier and moon visibility.\nDefault: true")
	elseIf (a_option == enableWeaponSpeedAugment_OID_T || a_option == enableWeaponSpeedAugment_OID_B)
		SetInfoText("If true, attack speed is augmented based on weapon speed multiplier and moon visibility.\nDefault: true")
	elseIf (a_option == enableHealRateAugment_OID_T || a_option == enableHealRateAugment_OID_B)
		SetInfoText("If true, health regen rate is augmented based on heal rate multiplier and moon visibility.\nDefault: true")
	elseIf (a_option == enableStaminaRateAugment_OID_T || a_option == enableStaminaRateAugment_OID_B)
		SetInfoText("If true, stamina regen rate is augmented based on stamina rate multiplier and moon visibility.\nDefault: true")

	elseIf (a_option == speedMultiplier_OID_T || a_option == speedMultiplier_OID_S)
		SetInfoText("At night, the player's running speed is multiplied by this number times the moon visibility.\nDefault: 2.0")
	elseIf (a_option == jumpMultiplier_OID_T || a_option == jumpMultiplier_OID_S)
		SetInfoText("At night, the player's jump height is multiplied by this number times the moon visibility.\nDefault: 2.0")
	elseIf (a_option == attackDamageMultiplier_OID_T || a_option == attackDamageMultiplier_OID_S)
		SetInfoText("At night, the player's non-magic attack damage is multiplied by this number times the moon visibility.\nDefault: 2.0")
	elseIf (a_option == weaponSpeedMultiplier_OID_T || a_option == weaponSpeedMultiplier_OID_S)
		SetInfoText("At night, the player's attack speed is multiplied by this number times the moon visibility.\nDefault: 2.0")
	elseIf (a_option == healRateMultiplier_OID_T || a_option == healRateMultiplier_OID_S)
		SetInfoText("At night, the player's health regen rate is multiplied by this number times the moon visibility.\nDefault: 2.0")
	elseIf (a_option == staminaRateMultiplier_OID_T || a_option == staminaRateMultiplier_OID_S)
		SetInfoText("At night, the player's stamina regen rate is multiplied by this number times the moon visibility.\nDefault: 2.0")

	elseIf (a_option == alwaysChange_OID_T || a_option == ignoreLycanthropy_OID_B)
		SetInfoText("If true, the player will always forcibly transform at night, regardless of the current moon visibility.\nDefault: false")
	elseIf (a_option == enableHircineOverride_OID_T || a_option == ignoreLycanthropy_OID_B)
		SetInfoText("If true, the Ring of Hircine, when equipped, will prevent forced transformations from occuring at night.\nDefault: true")
	elseIf (a_option == beastMultiplier_OID_T || a_option == beastMultiplier_OID_S)
		SetInfoText("At night, the probability of the player forcibly transforming into a werewolf is equal to this number times the moon visibility")

	elseIf (a_option == isAugmented_OID_T)
		SetInfoText("If true, the player's stats are currently being augmented from the moon's power.")

	elseIf (a_option == restoreDefaults_OID_T)
		SetInfoText("Restores the defaults of all options in the mod")
	endIf

; ...
endEvent

; @implements SKI_ConfigBase
event OnOptionSelect(int a_option)
{Called when a non-interactive option has been selected}
	if (a_option == restoreDefaults_OID_T)
		restoreDefaults()
	elseIf (a_option == enableSpeedAugment_OID_B)
		enableSpeedAugment = !enableSpeedAugment
		SetToggleOptionValue(enableSpeedAugment_OID_B, enableSpeedAugment)
	elseIf (a_option == enableJumpAugment_OID_B)
		enableJumpAugment = !enableJumpAugment
		SetToggleOptionValue(enableJumpAugment_OID_B, enableJumpAugment)
	elseIf (a_option == enableAttackDamageAugment_OID_B)
		enableAttackDamageAugment = !enableAttackDamageAugment
		SetToggleOptionValue(enableAttackDamageAugment_OID_B, enableAttackDamageAugment)
	elseIf (a_option == enableWeaponSpeedAugment_OID_B)
		enableWeaponSpeedAugment = !enableWeaponSpeedAugment
		SetToggleOptionValue(enableWeaponSpeedAugment_OID_B, enableWeaponSpeedAugment)
	elseIf (a_option == enableHealRateAugment_OID_B)
		enableHealRateAugment = !enableHealRateAugment
		SetToggleOptionValue(enableHealRateAugment_OID_B, enableHealRateAugment)
	elseIf (a_option == enableStaminaRateAugment_OID_B)
		enableStaminaRateAugment = !enableStaminaRateAugment
		SetToggleOptionValue(enableStaminaRateAugment_OID_B, enableStaminaRateAugment)
	elseIf (a_option == ignoreLycanthropy_OID_B)
		ignoreLycanthropy = !ignoreLycanthropy
		SetToggleOptionValue(ignoreLycanthropy_OID_B, ignoreLycanthropy)
	elseIf (a_option == enableForcedChange_OID_B)
		enableForcedChange = !enableForcedChange
		SetToggleOptionValue(enableForcedChange_OID_B, enableForcedChange)
	elseIf (a_option == alwaysChange_OID_B)
		alwaysChange = !alwaysChange
		SetToggleOptionValue(alwaysChange_OID_B, alwaysChange)
	elseIf (a_option == enableHircineOverride_OID_B)
		enableHircineOverride = !enableHircineOverride
		SetToggleOptionValue(enableHircineOverride_OID_B, enableHircineOverride)
	endIf
; ...
endEvent

; @implements SKI_ConfigBase
event OnOptionDefault(int a_option)
{Called when resetting an option to its default value}
if (a_option == enableForcedChange_OID_T || a_option == enableForcedChange_OID_B)
	enableForcedChange = true
	setTextOptionValue(enableForcedChange_OID_T, "True")
	setToggleOptionValue(enableForcedChange_OID_B, true)
endIf
if (a_option == enableSpeedAugment_OID_T || a_option == enableSpeedAugment_OID_B)
	enableSpeedAugment = true
	setTextOptionValue(enableSpeedAugment_OID_T, "True")
	setToggleOptionValue(enableSpeedAugment_OID_B, true)
endIf
if (a_option == enableJumpAugment_OID_T || a_option == enableJumpAugment_OID_B)
	enableJumpAugment = true
	setTextOptionValue(enableJumpAugment_OID_T, "True")
	setToggleOptionValue(enableJumpAugment_OID_B, true)
endIf
if (a_option == enableAttackDamageAugment_OID_T || a_option == enableAttackDamageAugment_OID_B)
	enableAttackDamageAugment = true
	setTextOptionValue(enableAttackDamageAugment_OID_T, "True")
	setToggleOptionValue(enableAttackDamageAugment_OID_B, true)
endIf
if (a_option == enableWeaponSpeedAugment_OID_T || a_option == enableWeaponSpeedAugment_OID_B)
	enableWeaponSpeedAugment = true
	setTextOptionValue(enableWeaponSpeedAugment_OID_T, "True")
	setToggleOptionValue(enableWeaponSpeedAugment_OID_B, true)
endIf
if (a_option == enableHealRateAugment_OID_T || a_option == enableHealRateAugment_OID_B)
	enableHealRateAugment = true
	setTextOptionValue(enableHealRateAugment_OID_T, "True")
	setToggleOptionValue(enableHealRateAugment_OID_B, true)
endIf
if (a_option == enableStaminaRateAugment_OID_T || a_option == enableStaminaRateAugment_OID_B)
	enableStaminaRateAugment = true
	setTextOptionValue(enableStaminaRateAugment_OID_T, "True")
	setToggleOptionValue(enableStaminaRateAugment_OID_B, true)
endIf

if (a_option == speedMultiplier_OID_T || a_option == speedMultiplier_OID_S)
	speedMultiplier = 2.0
	setTextOptionValue(speedMultiplier_OID_T, "2.0")
	setSliderOptionValue(speedMultiplier_OID_S, 2.0, "{0}")
endIf
if (a_option == jumpMultiplier_OID_T || a_option == jumpMultiplier_OID_S)
	jumpMultiplier = 2.0
	setTextOptionValue(jumpMultiplier_OID_T, "2.0")
	setSliderOptionValue(jumpMultiplier_OID_S, 2.0, "{0}")
endIf
if (a_option == attackDamageMultiplier_OID_T || a_option == attackDamageMultiplier_OID_S)
	attackDamageMultiplier = 2.0
	setTextOptionValue(attackDamageMultiplier_OID_T, "2.0")
	setSliderOptionValue(attackDamageMultiplier_OID_S, 2.0, "{0}")
endIf
if (a_option == weaponSpeedMultiplier_OID_T || a_option == weaponSpeedMultiplier_OID_S)
	weaponSpeedMultiplier = 2.0
	setTextOptionValue(weaponSpeedMultiplier_OID_T, "2.0")
	setSliderOptionValue(weaponSpeedMultiplier_OID_S, 2.0, "{0}")
endIf
if (a_option == healRateMultiplier_OID_T || a_option == healRateMultiplier_OID_S)
	healRateMultiplier = 2.0
	setTextOptionValue(healRateMultiplier_OID_T, "2.0")
	setSliderOptionValue(healRateMultiplier_OID_S, 2.0, "{0}")
endIf
if (a_option == staminaRateMultiplier_OID_T || a_option == staminaRateMultiplier_OID_S)
	staminaRateMultiplier = 2.0
	setTextOptionValue(staminaRateMultiplier_OID_T, "2.0")
	setSliderOptionValue(staminaRateMultiplier_OID_S, 2.0, "{0}")
endIf

if (a_option == alwaysChange_OID_T || alwaysChange_OID_B)
	alwaysChange = true
	setTextOptionValue(alwaysChange_OID_T, "True")
	setToggleOptionValue(alwaysChange_OID_B, true)
endIf
if (a_option == enableHircineOverride_OID_T || a_option == enableHircineOverride_OID_B)
	enableHircineOverride = true
	setTextOptionValue(enableHircineOverride_OID_T, "True")
	setToggleOptionValue(enableHircineOverride_OID_B, true)
endIf
if (a_option == beastMultiplier_OID_T || a_option == beastMultiplier_OID_S)
	beastMultiplier = 1.0
	setTextOptionValue(beastMultiplier_OID_T, "True")
	setToggleOptionValue(beastMultiplier_OID_S, true)
endIf

if (a_option == ignoreLycanthropy_OID_T || a_option == ignoreLycanthropy_OID_B)
	ignoreLycanthropy = false
	setTextOptionValue(ignoreLycanthropy_OID_T, "False")
	setToggleOptionValue(ignoreLycanthropy_OID_B, false)
endIf
; ...
endEvent

; @implements SKI_ConfigBase
event OnOptionSliderOpen(int a_option)
{Called when a slider option has been selected}
	if (a_option == speedMultiplier_OID_S)
		setSliderDialogStartValue(2.0)
		setSliderDialogRange(1.0, 5.0)
		setSliderDialogInterval(0.1)
	elseIf (a_option == jumpMultiplier_OID_S)
		setSliderDialogStartValue(2.0)
		setSliderDialogRange(1.0, 5.0)
		setSliderDialogInterval(0.1)
	elseIf (a_option == attackDamageMultiplier_OID_S)
		setSliderDialogStartValue(2.0)
		setSliderDialogRange(1.0, 5.0)
		setSliderDialogInterval(0.1)
	elseIf (a_option == weaponSpeedMultiplier_OID_S)
		setSliderDialogStartValue(2.0)
		setSliderDialogRange(1.0, 5.0)
		setSliderDialogInterval(0.1)
	elseIf (a_option == healRateMultiplier_OID_S)
		setSliderDialogStartValue(2.0)
		setSliderDialogRange(1.0, 5.0)
		setSliderDialogInterval(0.1)
	elseIf (a_option == staminaRateMultiplier_OID_S)
		setSliderDialogStartValue(2.0)
		setSliderDialogRange(1.0, 5.0)
		setSliderDialogInterval(0.1)
	elseIf (a_option == beastMultiplier_OID_S)
		setSliderDialogStartValue(1.0)
		setSliderDialogRange(0.0, 4.0)
		setSliderDialogInterval(0.1)
	endIf

; ...
endEvent

; @implements SKI_ConfigBase
event OnOptionSliderAccept(int a_option, float a_value)
{Called when a new slider value has been accepted}
	String temp
	if (a_option == speedMultiplier_OID_S)
		speedMultiplier = a_value
		setSliderOptionValue(speedMultiplier_OID_S, speedMultiplier, "{1}")
	elseIf (a_option == jumpMultiplier_OID_S)
		jumpMultiplier = a_value
		setSliderOptionValue(jumpMultiplier_OID_S, jumpMultiplier, "{1}")
	elseIf (a_option == attackDamageMultiplier_OID_S)
		attackDamageMultiplier = a_value
		setSliderOptionValue(attackDamageMultiplier_OID_S, attackDamageMultiplier, "{1}")
	elseIf (a_option == weaponSpeedMultiplier_OID_S)
		weaponSpeedMultiplier = a_value
		setSliderOptionValue(weaponSpeedMultiplier_OID_S, weaponSpeedMultiplier, "{1}")
	elseIf (a_option == healRateMultiplier_OID_S)
		healRateMultiplier = a_value
		setSliderOptionValue(healRateMultiplier_OID_S, healRateMultiplier, "{1}")
	elseIf (a_option == staminaRateMultiplier_OID_S)
		staminaRateMultiplier = a_value
		setSliderOptionValue(staminaRateMultiplier_OID_S, staminaRateMultiplier, "{1}")
	elseIf (a_option == beastMultiplier_OID_S)
		beastMultiplier = a_value
		setSliderOptionValue(beastMultiplier_OID_S, beastMultiplier, "{1}")
	endIf

; ...
endEvent

; @implements SKI_ConfigBase
event OnOptionMenuOpen(int a_option)
{Called when a menu option has been selected}

; ...
endEvent

; @implements SKI_ConfigBase
event OnOptionMenuAccept(int a_option, int a_index)
{Called when a menu entry has been accepted}

; ...
endEvent

; @implements SKI_ConfigBase
event OnOptionColorOpen(int a_option)
{Called when a color option has been selected}

; ...
endEvent

; @implements SKI_ConfigBase
event OnOptionColorAccept(int a_option, int a_color)
{Called when a new color has been accepted}

; ...
endEvent

; @implements SKI_ConfigBase
event OnOptionKeyMapChange(int a_option, int a_keyCode, string a_conflictControl, string a_conflictName)
{Called when a key has been remapped}

; ...
endEvent

;===================================================================================
;
;	Starts loop that checks whether or not it is nighttime (to augment stats/force
;	werewolf transformation. Polls for updates every updateInterval seconds
;
;===================================================================================
Event OnUpdate()
	if (isWerewolf || ignoreLycanthropy)
		toggleChangesIfApplicable()
	endIf
	RegisterForSingleUpdate(updateInterval)
endEvent

;===================================================================================
;
;	Called by the onUpdate() method. Checks to see which updates can be applied
;
;===================================================================================
Function toggleChangesIfApplicable()
	; if it is nighttime, check to see if we can force a transformation and apply any stat bonuses
	if (isNighttime())
		; if it has been more than than 11 hours since our last change and it is nighttime, then it is a new night
		float time = GetCurrentGameTime() * 24.0
		if ((time - lastChangeTime) > 11.0)
			hasChanged = false ; resets hasChanged to false, since it is a new night (new forced transformation attempt available)

			; if the bonuses from the last night are still in effect, we need to remove them
			if (isAugmented)
				resetStats()
				isAugmented = false
			endIf

			lastChangeTime = time ; update lastChangeTime to current time
		endIf
		; if a forced transformation has not yet been attempted
		if (!hasChanged)
			forceTransformation() ; attempt to force transformation
			hasChanged = true ; remember that forced transformation was attempted so we don't attempt twice in one night
		endIf

		if (!isAugmented)
			augmentStats() ; apply bonuses to player
			isAugmented = true ; remember that bonuses were applied so we don't apply any additonal bonuses
		endIf
		; in the case that it is nighttime but the previous night's augments have yet to be removed
	else
		hasChanged = false
		if (isAugmented)
			resetStats()
			isAugmented = false
		endIf
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

	Debug.Notification("Augmenting stats...")

	float baseSpeedMult = PlayerRef.GetBaseActorValue("SpeedMult")
	float baseJumpBonus = PlayerRef.GetBaseActorValue("JumpBonus")
	float baseAttackDamageMult = PlayerRef.GetBaseActorValue("attackDamageMult")
	float baseWeaponSpeedMult = PlayerRef.GetBaseActorValue("WeaponSpeedMult")
	float baseHealRate = PlayerRef.GetBaseActorValue("HealRate")
	float baseStaminaRate = PlayerRef.GetBaseActorValue("StaminaRate")

	float moonModifier = GetMoonModifier()


	if (enableSpeedAugment)
		speedBonus= baseSpeedMult * speedMultiplier * moonModifier
		PlayerRef.ModActorValue("SpeedMult", speedBonus)
	endIf
	if (enableJumpAugment)
		jumpBonus = baseJumpBonus * jumpMultiplier * moonModifier
		PlayerRef.ModActorValue("JumpBonus", jumpBonus)
	endIf
	if (enableAttackDamageAugment)
		attackDamageBonus = baseAttackDamageMult * attackDamageMultiplier * moonModifier
		PlayerRef.ModActorValue("attackDamageMult", attackDamageBonus)
	endIf
	if (enableWeaponSpeedAugment)
		weaponSpeedBonus = baseWeaponSpeedMult * weaponSpeedMultiplier * moonModifier
		PlayerRef.ModActorValue("WeaponSpeedMultiplier", weaponSpeedBonus)
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
;	Removes bonuses applied to actor values if any of these have been applied
;
;===================================================================================
function resetStats()
	PlayerRef.ModActorValue("SpeedMult", (-1) * speedBonus)
	PlayerRef.ModActorValue("JumpBonus", (-1) * jumpBonus)
	PlayerRef.ModActorValue("attackDamageMult", (-1) * attackDamageBonus)
	PlayerRef.ModActorValue("WeaponSpeedMultiplier", (-1) * weaponSpeedBonus)
	PlayerRef.ModActorValue("HealRate", (-1) * healRateBonus)
	PlayerRef.ModActorValue("StaminaRate", (-1) * staminaRateBonus)
endFunction

;===================================================================================
;
;	Forces a werewolf transformation if possible (must pass probability check and 
;	fail the Hircine Ring Override)
;
;===================================================================================
function forceTransformation()
	Debug.Notification("Forcing transformation...")
	if (enableHircineOverride && hasRingEquipped())
		Debug.Notification("Hircine Override. No transformation occurs.")
		return ; no transformation enabled
	elseIf (alwaysChange)
		Debug.Notification("Always change enabled. Attempting to force change...")
		WerewolfChangeRingOfHircine.Cast(PlayerRef) ; change always will occur at night
		;WerewolfChange.Cast(PlayerRef)
	else
		Debug.Notification("No Hircine Override. Attempting to force change...")
		float random = Utility.RandomFloat()
		if (beastMultiplier * GetMoonModifier() >= random)
			Debug.Notification("Forced change successful.")
			WerewolfChangeRingOfHircine.Cast(PlayerRef) ; change may randomly occur at night
			;WerewolfChange.Cast(PlayerRef)
		endIf
	endIf
endFunction

;===================================================================================
;
;	Restores all of the default settings
;
;===================================================================================
function restoreDefaults()
	OnOptionDefault(enableForcedChange_OID_T)
	OnOptionDefault(enableSpeedAugment_OID_T)
	OnOptionDefault(enableJumpAugment_OID_T)
	OnOptionDefault(enableAttackDamageAugment_OID_T)
	OnOptionDefault(enableWeaponSpeedAugment_OID_T)
	OnOptionDefault(enableHealRateAugment_OID_T)
	OnOptionDefault(enableStaminaRateAugment_OID_T)
	OnOptionDefault(speedMultiplier_OID_T)
	OnOptionDefault(jumpMultiplier_OID_T)
	OnOptionDefault(attackDamageMultiplier_OID_T)
	OnOptionDefault(weaponSpeedMultiplier_OID_T)
	OnOptionDefault(healRateMultiplier_OID_T)
	OnOptionDefault(staminaRateMultiplier_OID_T)
	OnOptionDefault(alwaysChange_OID_T)
	OnOptionDefault(enableHircineOverride_OID_T)
	OnOptionDefault(beastMultiplier_OID_T)
	OnOptionDefault(ignoreLycanthropy_OID_T)
endFunction

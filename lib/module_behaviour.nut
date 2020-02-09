//---------- DOCUMENTATION ----------

/**
FUNCTIONS FOR CONTROLLING BOT BEHAVIOUR (AI)
! requires lib/module_base !
! requires lib/module_tasks !
------------------------------------

 */

//---------- CODE ----------

this = ::root

log("[lib] including module_behaviour")

_def_constvar("UserCmd", class {
	
	ent = null
	
	constructor(entity) { ent = entity.weakref() }
	
	function angles(pitch, yaw) { ent.SetForwardVector(QAngle(pitch, yaw, 0).Forward()) }
		
	function forward(_forward) { ent.SetForwardVector(_forward) }
	
	function freeze() { set_entity_flag(ent, FL_FROZEN, true) }
	
	function unfreeze() { set_entity_flag(ent, FL_FROZEN, false) }
	
	function hold(button) {
		propint(ent, "m_afButtonForced", propint(ent, "m_afButtonForced") | button)
	}
	
	function block(button) {
		propint(ent, "m_afButtonDisabled", propint(ent, "m_afButtonDisabled") | button)
	}
	
	function unblock(button) {
		propint(ent, "m_afButtonDisabled", propint(ent, "m_afButtonDisabled") &~ button)
	}
	
	function release(button) {
		propint(ent, "m_afButtonForced", propint(ent, "m_afButtonForced") &~ button)
		block(button)
		run_next_tick(ent, @()unblock(button) )
	}
	
	function tap(button) {
		hold(button)
		run_next_tick(ent, @()release(button) )
	}
})

_def_constvar("NextBot", class {
	
	ent = null
	_cmdTable = null
	
	constructor(entity) {
		ent = entity.weakref()
		_cmdTable = { cmd = null, bot = entity.weakref(), pos = null, target = null }
	}
	
	function setSenseFlags(flags) { ent.SetSenseFlags(flags) }
	
	function blind(bool = true) { ent.SetSenseFlags(bool ? -1 : 0) }
	
	function move(pos) {
		_cmdTable.cmd = BOT_CMD_MOVE
		_cmdTable.pos = pos
		CommandABot(_cmdTable)
	}
	
	function attack(target) {
		_cmdTable.cmd = BOT_CMD_ATTACK
		_cmdTable.target = target
		CommandABot(_cmdTable)
	}
	
	function retreat(target) {
		_cmdTable.cmd = BOT_CMD_RETREAT
		_cmdTable.target = target
		CommandABot(_cmdTable)
	}
	
	function reset() {
		_cmdTable.cmd = BOT_CMD_RESET
		CommandABot(_cmdTable)
	}
	
})

_def_constvar("BehaviourTarget", class {

	ent = null
	scope = null
	
	UserCmd = null
	NextBot = null
	
	constructor(entity) {
		ent = entity.weakref()
		scope = ::scope(entity)
		UserCmd = ::UserCmd(entity)
		NextBot = ::NextBot(entity)
	}
	
	function valid() { return !invalid(ent) }
	
	function pos() { return ent.GetOrigin() }
	
	function ang() { return ent.EyeAngles() }
	
	function forward() { return ent.EyeAngles().Forward() }
	
	function bodyForward() { return ent.GetForwardVector() }
	
	function left() { return ent.EyeAngles().Left() }
	
	function vel() { return ent.GetVelocity() }
	
	function inAir() { return propint(ent, "m_hGroundEntity") == -1 }
	
	function ducked() { return propint(ent, "m_Local.m_bDucked") }
	
	function flag(_flag) { return propint(ent, "m_fFlags") & _flag }
	
	function cooldown() { 
		local ability = propent(ent, "m_customAbility")
		local nextActivation = propfloat(ability, "m_nextActivationTimer.m_timestamp")
		return max(0, nextActivation - Time())
	}
	
})
require('class')

SimpleStateMachine = class()

function SimpleStateMachine:init()
	self.states = {}
	self.currentState = nil
end

function SimpleStateMachine:get_state()
	return self.currentState
end

function SimpleStateMachine:set_state(name)	
	if name == self.currentState then
		return
	end
	if self.states[self.currentState] then
		if self.states[self.currentState].onExit and type(self.states[self.currentState].onExit) == "function" then
			self.states[self.currentState].onExit()
		end		
	end			
	if self.states[name] then		
		self.currentState = name
		if self.states[self.currentState] and type(self.states[self.currentState].onEnter) == "function" then
			self.states[self.currentState].onEnter()
		end
	end
end

function SimpleStateMachine:tick()
	if self.states[self.currentState] then
		if self.states[self.currentState].onTick and type(self.states[self.currentState].onTick) == "function" then
			self.states[self.currentState].onTick()
		end
	end
end

function SimpleStateMachine:register(name, onEnter, onTick, onExit)	
	self.states[name] = { onEnter = onEnter, onTick = onTick, onExit = onExit }	
end
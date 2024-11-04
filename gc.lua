--[[

    @title GC
    @author darmyn AKA darmantinjr
    @description helps manage memory usage & leaks.

]]

local DESTROY_METHOD_NAMES = {
	"destroy", "Destroy",
}

local function isFunction(value: any)
	if value and typeof(value) == "function" then
		return true
	else
		return false
	end
end

local function attemptCallMethods(object, methodNames: {string}, ...)
	for _, methodName in ipairs(methodNames) do
		local method = object[methodName]
		if isFunction(method) then
			method(object, ...)
		end
	end
end

local GC = {public = {}, private = {}}
GC.public.interface = {}
GC.public.behavior = {}
GC.public.meta = {__index = GC.public.behavior}
GC.private.behavior = {}
GC.private.memory = {}

function GC.public.interface.new()
	local public = setmetatable({}, GC.public.meta)
	local private = setmetatable(table.clone(GC.private.behavior), {__index = public})
	
	private.garbage = {}
	
	GC.private.memory[public] = private
	return public
end

function GC.public.behavior.collect(self: GCPublic, garbage: {any})
	local private = GC.private.memory[self]
	for _, trash in garbage do
		table.insert(private.garbage, trash)
	end
end

function GC.public.behavior.clean(self: GCPublic, ...)
	local private = GC.private.memory[self]
	
	for _, trash in private.garbage do
		if typeof(trash) == "Instance" then
			trash:Destroy()
		elseif typeof(trash) == "RBXScriptConnection" then
			trash:Disconnect()
		elseif isFunction(trash) then      
			trash(...)
		elseif typeof(trash) == "table" then
			print("TABLE")
			attemptCallMethods(trash, DESTROY_METHOD_NAMES, ...)
		end
	end
	
	table.clear(private.garbage)
end

function GC.public.behavior.destroy(self: GCPublic)
	self:clean()
	GC.private.memory[self] = nil
end

type GCPublic = typeof(GC.public.interface.new(...))
type GCPrivate = typeof(GC.private.memory[...])
export type Type = GCPublic

return GC.public.interface

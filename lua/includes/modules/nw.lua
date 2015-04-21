nw 				= nw 			or {}
nw.Stored 		= nw.Stored 	or {}
nw.VarFuncs		= nw.VarFuncs 	or {}
nw.Callbacks 	= nw.Callbacks 	or {}

local nw 		= nw
local net 		= net
local pairs 	= pairs
local Entity 	= Entity
local player 	= player

local ENTITY 	= FindMetaTable('Entity')

local ReadType
local GetFilter
if (SERVER) then
	util.AddNetworkString('nw.var')
	util.AddNetworkString('nw.clear')
	util.AddNetworkString('nw.delete')
	util.AddNetworkString('nw.ping')

	function GetFilter(ent, var, value)
		return (nw.VarFuncs[var] ~= nil and nw.VarFuncs[var].Filter ~= nil) and nw.VarFuncs[var].Filter(ent, var, value) or player.GetAll()
	end

	local function SendVar(ent, var, value, filter)
		if (nw.VarFuncs[var] ~= nil) and (nw.VarFuncs[var].Send ~= nil) then
			nw.VarFuncs[var].Send(ent, value, filter)
		else
			local index = ent:EntIndex()
			
			net.Start('nw.var')
				net.WriteUInt(index, 16)
				net.WriteString(var)
				net.WriteType(value)
			net.Broadcast()

			MsgC(Color(255,0,0), 'UNREGISTERED VAR: ' .. var)
		end
	end

	function ENTITY:SetNetVar(var, value)
		local index = self:EntIndex()
		
		if (nw.Stored[index] == nil) then
			nw.Stored[index] = {}
		end

		nw.Stored[index][var] = value

		SendVar(self, var, value)
	end

	net.Receive('nw.ping', function(len, pl)
		if (pl.EntityCreated ~= true) then
			hook.Call('PlayerEntityCreated', GAMEMODE, pl)

			pl.EntityCreated = true

			for index, vars in pairs(nw.Stored) do
				local ent = Entity(index)
				for var, value in pairs(vars) do
					SendVar(Entity(index), var, value, pl)
				end
			end

			if (nw.Callbacks[pl] ~= nil) then
				for k, v in ipairs(nw.Callbacks[pl]) do
					v(pl)
				end
			end
			nw.Callbacks[pl] = nil
		end
	end)

	function nw.WaitForPlayer(pl, callback)
		if (pl.EntityCreated == true) then
			callback(pl)
			return
		end
		if (nw.Callbacks[pl] == nil) then
			nw.Callbacks[pl] = {}
		end
		nw.Callbacks[pl][#nw.Callbacks[pl] + 1] = callback
	end

	hook.Add('EntityRemoved', 'nw.EntityRemoved', function(ent)
		local index = ent:EntIndex()
		if (nw.Stored[index] ~= nil) then
			net.Start('nw.clear')
				net.WriteUInt(index, 12)
			net.Broadcast()
			nw.Stored[index] = nil
		end
	end)
elseif (CLIENT) then
	function ReadType()
		local t = net.ReadUInt(8)
		return net.ReadType(t)
	end

	net.Receive('nw.var', function()
		local index = net.ReadUInt(12)
		local var 	= net.ReadString()
		local value = ReadType()

		if (nw.Stored[index] == nil) then
			nw.Stored[index] = {}
		end

		nw.Stored[index][var] = value
	end)

	net.Receive('nw.clear', function()
		nw.Stored[net.ReadUInt(12)] = nil
	end)

	net.Receive('nw.delete', function()
		local index = net.ReadUInt(12)
		if (nw.Stored[index] ~= nil) then
			nw.Stored[index][net.ReadString()] = nil
		end
	end)

	hook.Add('InitPostEntity', 'nw.InitPostEntity', function()
		net.Start('nw.ping')
		net.SendToServer()
	end)
end

function ENTITY:GetNetVar(var)
	local index = self:EntIndex()
	if (nw.Stored[index] ~= nil) then
		return nw.Stored[index][var]
	end
	return nil
end

function nw.Register(var, funcs) -- always call this shared
	if (SERVER) then
		util.AddNetworkString('nw_' ..  var)
	elseif (CLIENT) then
		local ReadFunc = ((funcs and funcs.Read) and funcs.Read or ReadType)

		net.Receive('nw_' ..  var, function()
			local index = net.ReadUInt(12)
			local value = ReadFunc()

			if (nw.Stored[index] == nil) then
				nw.Stored[index] = {}
			end

			nw.Stored[index][var] = value
		end)
	end

	local WriteFunc = ((funcs and funcs.Write) and funcs.Write or net.WriteType)

	nw.VarFuncs[var] = {
		Send 	= function(ent, value, filter)
			local index = ent:EntIndex()

			if (value == nil) then
				net.Start('nw.delete')
					net.WriteUInt(index, 12)
					net.WriteString(var)
				net.Send(filter or GetFilter(ent, var, value))
				return
			end

			net.Start('nw_' ..  var)
				net.WriteUInt(index, 12)
				WriteFunc(value)
			net.Send(filter or GetFilter(ent, var, value))
		end,
		Filter 	= (funcs and funcs.Filter or nil)
	}
end
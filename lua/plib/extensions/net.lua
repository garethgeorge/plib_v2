local WriteUInt = net.WriteUInt
local ReadUInt 	= net.ReadUInt
local WriteBit 	= net.WriteBit
local ReadBit 	= net.ReadBit

function net.WriteNibble(i)
	WriteUInt(i, 4)
end

function net.ReadNibble()
	return ReadUInt(4)
end

function net.WriteByte(i)
	WriteUInt(i, 8)
end

function net.ReadByte()
	return ReadUInt(8)
end

function net.WriteShort(i)
	WriteUInt(i, 16)
end

function net.ReadShort()
	return ReadUInt(16)
end

function net.WriteLong(i)
	WriteUInt(u, 32)
end

function net.ReadLong()
	return ReadUInt(i, 32)
end

function net.WriteBool(i)
	WriteBit(i and 1 or 0)
end

function net.ReadBool()
	return (ReadBit() == 1)
end
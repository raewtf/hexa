-- xorshift Lua implementation from Eli Piilonen/2DArray
-- Dedicated to CC0

randState = 12345

-- seed the PRNG with an integer value - but not zero!
function setRandomSeed(seed)
	local intSeed = tonumber(seed)
	if intSeed == 0 then
		print("setRandomSeed() must be called with a nonzero value!")
	else
		randState = intSeed & 2147483647
	end
end

function xorshift32()
	-- Algorithm "xor" from p. 4 of Marsaglia, "Xorshift RNGs"
	local x = randState
	x = (x ~ (x << 13)) & 2147483647
	x = (x ~ (x >> 17)) & 2147483647
	x = (x ~ (x << 5)) & 2147483647
	randState = x
	return x
end

function randFloat(minInclusive, maxExclusive)
	minInclusive = minInclusive or 0
	maxExclusive = maxExclusive or 1
	local t
	t = (xorshift32() & 65535) / 65536
	return minInclusive + t * (maxExclusive - minInclusive)
end

function randInt(minInclusive, maxInclusive)
	return math.abs(xorshift32()) % (maxInclusive + 1 - minInclusive) + minInclusive
end

function randArrayElement(arrayTable)
	local count = #arrayTable
	if count == 0 then
		return nil
	end

	local index = randInt(1, count)
	return arrayTable[index]
end
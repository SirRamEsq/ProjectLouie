local f = {}

--will return true if ONLY ONE of the inputs is true
function f.XOR(v1, v2)
	--if both true
	if v1 and v2 then return false end
	--if both false
	if not v1 and not v2 then return false end
	--if only one is true
	if v1 or v2 then return true end

	return false
end

function f.AngleToSignedAngle(a)
	if(a>180)then
		a= a - 360;
	end
	return a;
end

function f.SignedAngleToAngle(a)
	if(a<0)then
		a= a + 360;
	end
	return a;
end

function f.InvertHeightMap(hm)
	return 16-hm;
end

function f.TableEmpty(t)
	if next(t) == nil then return true end
	return false
end

function f.PrintTableRecursive(t, recurseLevel)
	local retString = "    "
	local recurse = recurseLevel or 0
	if t == nil then
		return "\nTABLE IS NIL"
	end

	if f.TableEmpty(t) then
		retString = retString .. "\n"
		for i=0,recurse do
			--indent
			retString = retString .. " |"
		end
		retString = retString .. "TABLE EMPTY"
		return retString
	end

	for k,v in pairs(t)do
		--newline
		retString = retString .. "\n"
		for i=0,recurse do
			--indent
			retString = retString .. " |"
		end
		retString = retString .. "["..tostring(k).."] = "..tostring(v)
		if(type(v) == "table")then
			retString = retString .. f.PrintTableRecursive(v, recurse + 1)
		end
	end
	return retString
end

return f

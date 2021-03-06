local collectableFlags = require("Utility/collectableFlags.lua")

function Collectable.new(base)
	local collectable = base or {}

	--will return what collectable type this is
	function collectable.Collect()
		return collectableFlags.Generic
	end

	collectable.EntityInterface = {
	  IsCollectable	  = function () return collectable.Collect();  end,
	}

	return collectable;
end

return Collectable.new

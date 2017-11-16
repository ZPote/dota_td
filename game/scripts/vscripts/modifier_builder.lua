modifier_builder = class({})

function modifier_builder:DeclareFunctions()
	return {
        MODIFIER_PROPERTY_DISABLE_TURNING,
        MODIFIER_PROPERTY_IGNORE_CAST_ANGLE
    }
end

function modifier_builder:CheckState()
	local state = {
		[MODIFIER_STATE_ROOTED] = true,
	}
	return state
end

function modifier_builder:GetModifierDisableTurning(params)
    return 1
end

function modifier_builder:GetModifierIgnoreCastAngle(params)
    return 1
end

function modifier_builder:IsHidden()
    return true
end

function modifier_builder:IsPermanent()
	return true
end
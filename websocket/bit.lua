local band = function(a, b)
    return a & b
end

local bor = function(a, b)
    return a | b
end

local bnand = function(a, b)
    return ~band(a, b)
end

local bxor = function(a, b)
    return band(bor(a, b), bnand(a, b))
end

local lshift = function(a, b)
    return a << b
end

local rshift = function(a, b)
    return a >> b
end

return {
    band = band,
    bor = bor,
    bnand = bnand,
    bxor = bxor,
    lshift = lshift,
    rshift = rshift
}

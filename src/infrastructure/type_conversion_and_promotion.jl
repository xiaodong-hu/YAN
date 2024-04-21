# ============================================================================================================================
# ========================================= Conversion and Promotion Rules ===================================================
# ============================================================================================================================

# important to make sure the construction of array and sparse array of both symbolic and numerical values to be OK
Base.convert(::Type{U}, x::T) where {U<:Sym,T<:Number} = _sym(x)

Base.convert(::Type{U}, x::T) where {U<:MathTerm,T<:Number} = Num(x)

# important to make sure parametric type is correctly inferred. For example `[1,x] isa Vector{MathExpr}` instead of `Vector{Number}`
Base.convert(::Type{U}, x::T) where {U<:MathExpr,T<:Number} = MathExpr(Num(x))


# these two promotion rules will implicitly invoke the above `convert(::Type{MathExpr}, x::T) where {T<:Number}`
Base.promote_rule(::Type{T}, ::Type{S}) where {T<:MathExpr,S<:Number} = MathExpr
Base.promote_rule(::Type{S}, ::Type{T}) where {T<:MathExpr,S<:Number} = MathExpr




Base.promote_rule(::Type{S}, ::Type{T}) where {T<:MathTerm,S<:MathTerm} = MathExpr
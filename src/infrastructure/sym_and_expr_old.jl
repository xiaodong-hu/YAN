# ======================================== Core Data Structures for Symbolic Computation ===================================================
"""
Struct `Sym{T}` for Symbolic Variable
---
of datatype T.
"""
struct Sym{T}
    repr::Symbol # variable name
end

"simple internal constructor for symbolic variables"
_sym(T::Type, x) = Sym{T}(Symbol(x))
_sym(x::T) where {T<:Number} = Sym{T}(Symbol(x))

"helper function to get the datatype of a `Sym`"
symtype(::Sym{T}) where {T} = T


# Core building blocks for symbolic expressions
@data MathTerm <: Number begin
    Num(num::Number)
    Var(var::Sym)
    UnaryTerm(op::Symbol, arg::MathTerm)
    BinaryTerm(op::Symbol, left::MathTerm, right::MathTerm)
end
"get the string representation for `MathTerm`"
function _get_string_repr_for_math_term(m::MathTerm)
    @match m begin
        Num(x) => x
        Var(var) => var.repr
        UnaryTerm(op, arg) => String(op) * "($(_get_string_repr_for_math_term(arg)))"
        BinaryTerm(op, left, right) => "($(_get_string_repr_for_math_term(left)) " * String(op) * " $(_get_string_repr_for_math_term(right)))"
    end
end
Base.show(io::IO, m::MathTerm) = print(io, _get_string_repr_for_math_term(m))



"helper function to get the datatype of a `MathTerm`"
function symtype(m::MathTerm)
    @match m begin
        Num(x) => symtype(x)
        Var(var) => symtype(var)
        UnaryTerm(op, arg) => symtype(arg)
        BinaryTerm(op, left, right) => promote_type(symtype(left), symtype(right))
    end
end

"""
Struct `MathExpr` for ALL Symbolic Expressions
---
as a unified type wrapper for `MathTerm`. 
- Fields:
    - `content::MathTerm`: wrapped math terms, including `Num`, `Var`, `UnaryTerm`, and `BinaryTerm`

Note: we need `MathExpr<:Number` to make it support auto-promotion of arithmetic operator involving `AbstractArray`.
"""
struct MathExpr <: Number
    content::MathTerm
end
"extend constructor for `Number`"
MathExpr(x::Number) = MathExpr(Num(x))

"overlaod `Base.show` for `MathExpr`"
Base.show(io::IO, m::MathExpr) = print(io, _get_string_repr_for_math_term(m.content))



"helper function to get the datatype of a `MathExpr`"
symtype(m::MathExpr) = symtype(m.content)

"helper function for general case"
symtype(x) = typeof(x)


# ======================================== Macro for Symbolic Variable Declaration ===================================================
const DEFAULT_SYM_DATATYPE::Type = Float64 # concrete type is preferred for defaut!

"""
The Vararg Macro to Declare Symbolic Variables <: MathExpr, with Optional Type Annotations
---
Example usage:
```julia
@vars x y::UInt32 z::Matrix{ComplexF64} # declare `x` as `DEFAULT_SYM_DATATYPE`, `y` as `UInt32`, and `z` as `Matrix{ComplexF64}`
```
If type is not specified, the default type `DEFAULT_SYM_DATATYPE=Float64` is set (you can modify this constant).
"""
macro vars(ex...)
    exprs = Expr(:block)  # Initialize an expression block to hold all declarations
    for item in ex
        if isa(item, Expr) && item.head == :(::) && isa(item.args[1], Symbol) # if with type annotations
            var_name = item.args[1]
            var_type = item.args[2]
            # Create a Sym of the specified type, wrap it in Var, and assign it to var_name
            new_var_expr = :($(esc(var_name)) = _sym($(esc(var_type)), $(string(var_name))) |> Var |> MathExpr)
        elseif isa(item, Symbol)
            # Create a Sym with the default type, wrap it in Var, and assign it to var_name
            new_var_expr = :($(esc(item)) = _sym(DEFAULT_SYM_DATATYPE, $(string(item))) |> Var |> MathExpr)
        else
            error("Invalid argument to @vars. Expect symbols or type annotations.")
        end
        push!(exprs.args, new_var_expr)
    end
    return exprs
end



# ======================================== Type Conversion and Promotion Rules ===================================================

# important to make sure the construction of array and sparse array of both symbolic and numerical values to be OK
Base.convert(::Type{U}, x::T) where {U<:Sym,T<:Number} = _sym(x)


# important to make sure parametric type is correctly inferred. For example `[1,x] isa Vector{MathExpr}` instead of `Vector{Number}`
Base.convert(::Type{U}, x::T) where {U<:MathExpr,T<:Number} = MathExpr(Num(x))


# these two promotion rules will implicitly invoke the above `convert(::Type{MathExpr}, x::T) where {T<:Number}`
Base.promote_rule(::Type{T}, ::Type{S}) where {T<:MathExpr,S<:Number} = MathExpr
Base.promote_rule(::Type{S}, ::Type{T}) where {T<:MathExpr,S<:Number} = MathExpr
Base.promote_rule(::Type{S}, ::Type{T}) where {T<:MathTerm,S<:MathTerm} = MathExpr
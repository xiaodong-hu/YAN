const DEFAULT_SYM_DATATYPE::Type = Float64 # concrete type is preferred for defaut!


# ======================================= Symbolic Variable =======================================
"""
Struct `Sym{T}` for Symbolic Variable
---
"""
struct Sym{T}
    string_repr::String # variable name
end

"simple internal constructor for symbolic variables"
_sym(T::Type, x) = Sym{T}(string(x))
_sym(x::T) where {T<:Number} = Sym{T}(string(x))


"helper function to get the datatype of a `Sym`"
symtype(::Sym{T}) where {T} = T

# ======================================= Symbolic Expression =======================================
# "Abstract Type for ALL Symbolic Terms"
# abstract type MathTerm end

# "Numeric Term"
# struct Num <: MathTerm
#     num::Number
# end

# "Variable Term"
# struct Var <: MathTerm
#     var::Sym
# end

# "Unary Term"
# struct UnaryTerm <: MathTerm
#     op::Symbol
#     arg::MathTerm
# end

# "Binary Term"
# struct BinaryTerm <: MathTerm
#     op::Symbol
#     left::MathTerm
#     right::MathTerm
# end

# only below `@data` can be used for `MLStyle.@match`
@data MathTerm <: Number begin
    Num(num::Number)
    Var(var::Sym)
    UnaryTerm(op::Symbol, arg::MathTerm)
    BinaryTerm(op::Symbol, left::MathTerm, right::MathTerm)
end


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
Struct `MathExpr` for ALL Symbolic expression
---
as a concrete type wrapper for `MathTerm`. Note: we need MathExpr to be subtype of Number to make it support auto-promotion of alrithmetic operator involving AbstractArray.



fields:
- `repr::MathTerm`: wrapped math terms, including `Var`, `UnaryTerm`, and `BinaryTerm`
"""
struct MathExpr <: Number
    repr::MathTerm
end
"extend constructor for `Number`"
MathExpr(x::Number) = MathExpr(Var(x))

"helper function to get the datatype of a `MathExpr`"
symtype(m::MathExpr) = symtype(m.repr)

"helper function for general case"
symtype(x) = typeof(x)


"get the string representation for `MathTerm`"
function _get_string_repr_for_math_term(m::MathTerm)::String
    @match m begin
        Num(x) => string(x)
        Var(var) => var.string_repr
        UnaryTerm(op, arg) => string(op) * "(" * _get_string_repr_for_math_term(arg) * ")"
        BinaryTerm(op, left, right) => "(" * _get_string_repr_for_math_term(left) * " " * string(op) * " " * _get_string_repr_for_math_term(right) * ")"
    end
end

"overlaod `Base.show` for `MathExpr`"
Base.show(io::IO, m::MathExpr) = print(io, _get_string_repr_for_math_term(m.repr))


# ======================================= Symbolic Variable Declaration =======================================
"""
Macro to Declare Multiple Symbolic Variables `<: MathExpr`, with Optional Type Annotations
---
Example usage:
```julia
@vars x y::UInt32 z::Matrix{ComplexF64} # declare `x` as Float64, `y` as UInt32, and `z` as Matrix{ComplexF64}
```
If type is not specified, the default type `DEFAULT_SYM_DATATYPE` is used.
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
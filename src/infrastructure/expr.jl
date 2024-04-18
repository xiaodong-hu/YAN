# depends on `MLStyle`
@data MathExpr begin
    Var(var::Union{Sym,Number}) # maybe using `var::Union{Sym, Number}` would speed up the evaluation
    UnaryTerm(op::Symbol, arg::MathExpr)
    BinaryTerm(op::Symbol, left::MathExpr, right::MathExpr)
end
@doc """
Enum `MathExpr` to Represent Mathematical Expressions
---
(Nested) Subtypes:
- `Var(var::Union{Sym,Number})`: a leaf node in the expression tree
- `UnaryTerm(op::Symbol, arg::MathExpr)`: a unary expression
- `BinaryTerm(op::Symbol, left::MathExpr, right::MathExpr)`: a binary expression
""" MathExpr
@doc "Subtype `Var(var::Union{Sym,Number}) <: MathExpr` as a leaf node in the expression tree" Var
@doc "Subtype `UnaryTerm(op::Symbol, arg::MathExpr) <: MathExpr` as a unary expression" UnaryTerm
@doc "Subtype `BinaryTerm(op::Symbol, left::MathExpr, right::MathExpr) as a binary expression" BinaryTerm


"get the string representation of a `MathExpr`"
function _get_repr_for_math_expr(m::MathExpr)
    @match m begin
        Var(var) => if var isa Sym
            return var.ref[]
        elseif var isa Number
            return string(var)
        end
        UnaryTerm(op, arg) => "$op($(_get_repr_for_math_expr(arg)))"
        BinaryTerm(op, left, right) => "($(_get_repr_for_math_expr(left)) $op $(_get_repr_for_math_expr(right)))"
    end
end
Base.show(io::IO, m::MathExpr) = print(io, _get_repr_for_math_expr(m))



"helper function to extract datatype of a symbolic terms and expressions"
symtype(m::MathExpr) = @match m begin
    Var(var) => return symtype(var)
    UnaryTerm(op, arg) => return symtype(arg)
    BinaryTerm(op, left, right) => return promote_type(symtype(left), symtype(right))
end

# helper constructor for function registeration, see macro `@register`
# UnaryTerm(f::Function, arg::MathExpr) = UnaryTerm(Symbol(f), arg)
# BinaryTerm(f::Function, left::MathExpr, right::MathExpr) = BinaryTerm(Symbol(f), left, right)
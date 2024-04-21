# ============================================================================================================================
# ====================================== Substitutions, Lambdification, and Evaluation =======================================
# ============================================================================================================================
"""
Substitute `MathExpr` Recursively.
"""
function _iterative_substitute(m::MathTerm, formated_sub_rules::Dict{MathTerm,MathTerm})::MathTerm
    # Base case: direct match (for expression input)
    v = get(formated_sub_rules, m, m)
    if v != m
        return v
    end

    # Recursive case: apply substitution to sub-expressions
    @match m begin
        Num(_) || Var(_) => m # unmatched symbol or number: no need to create a new instance
        UnaryTerm(op, arg) => UnaryTerm(op, _iterative_substitute(arg, formated_sub_rules))
        BinaryTerm(op, left, right) => BinaryTerm(op, _iterative_substitute(left, formated_sub_rules), _iterative_substitute(right, formated_sub_rules))
    end
end



"""
Replace ALL like Mathematica
---
Keep `_iterative_substitute` until no more substitution can be made.
"""
function replace_all(m::MathTerm, formated_sub_rules::Dict{MathTerm,MathTerm})::MathTerm
    new_m = m
    while true
        new_m = _iterative_substitute(new_m, formated_sub_rules)
        if new_m == m
            break
        end
        m = new_m
    end
    return new_m
end




"""
Substitute Symbolic Expression `MathExpr` with a Dict of Rules
---
Here the `input_rules` support symbolic, numeric, and even expressions.

The strategy is to first format the substitution rules to standard form `Dict{MathTerm,MathTerm}`, and then perform substitution recursively.
"""
function subs(m::MathExpr, input_sub_rules::Dict{T,U}; lazy::Bool=false) where {T,U}
    formated_sub_rules = Dict{MathTerm,MathTerm}()
    for (k, v) in input_sub_rules
        formated_key = @match k begin
            ::MathExpr => k.repr
            ::MathTerm => k
            _ => Num(k)
        end

        formated_value = @match v begin
            ::MathExpr => v.repr
            ::MathTerm => v
            ::Number => Num(v)
        end

        formated_sub_rules[formated_key] = formated_value
    end

    # @show formated_sub_rules
    new_expr::MathExpr = replace_all(m.repr, formated_sub_rules) |> MathExpr
    if lazy
        return new_expr
    else
        return evaluate(new_expr)
    end
end
subs(m::Number, input_sub_rules::Dict{T,U}; lazy::Bool=false) where {T,U} = m

"Evaluation of a `MathTerm` Expression"
function evaluate(m::MathTerm)::Union{MathTerm,Number}
    @match m begin
        Num(x) => eval(x)
        Var(var) => m # no need to create a new instance
        UnaryTerm(op, arg) => begin
            (eval(op))(evaluate(arg))
        end
        BinaryTerm(op, left, right) => begin
            (eval(op))(evaluate(left), evaluate(right))
        end
    end
end
"Evaluation of a `Number` does nothing"
evaluate(x::Number) = x

"Evaluation of a `MathExpr` Expression"
evaluate(x::MathExpr)::Union{Number,MathExpr} = begin
    eval_res = evaluate(x.repr)
    @match eval_res begin
        ::MathTerm => MathExpr(eval_res)
        ::Number => eval_res
    end
end




"""
Get the Set of Free Symbols in an Expression
---
by recursive search
"""
function free_symbols(m::MathTerm)
    var_set = Set{MathTerm}()
    @match m begin
        Num(_) => nothing
        Var(var) => push!(var_set, Var(var))
        UnaryTerm(op, arg) => begin
            var_set = var_set ∪ free_symbols(arg)
        end
        BinaryTerm(op, left, right) => begin
            var_set = var_set ∪ free_symbols(left) ∪ free_symbols(right)
        end
    end
    return var_set
end
free_symbols(m::MathExpr) = free_symbols(m.repr)
free_symbols(::Number) = Set{MathExpr}()

"get free symbol for `AbstractArray` (reduce from `free_symbols` of each element)"
free_symbols(A::AbstractArray) = reduce(∪, free_symbols.(A))
free_symbols(A::AbstractSparseArray) = free_symbols(A.nzval)
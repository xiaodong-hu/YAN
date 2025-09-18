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
        Num(_) || Var(_) => return m # unmatched symbol or number: no need to create a new instance
        UnaryTerm(op, arg) => return UnaryTerm(op, _iterative_substitute(arg, formated_sub_rules))
        BinaryTerm(op, left, right) => return BinaryTerm(op, _iterative_substitute(left, formated_sub_rules), _iterative_substitute(right, formated_sub_rules))
    end
end



"""
Replace ALL like Mathematica
---
Keep `_iterative_substitute` until no more substitution can be made.
"""
function replace_all(m::MathTerm, formated_sub_rules::Dict{MathTerm,MathTerm}; n_depth::Int=4096)::MathTerm
    new_m = m
    while true
        old_m = new_m
        new_m = _iterative_substitute(old_m, formated_sub_rules)
        if new_m == old_m
            break
        end
        n_depth -= 1
        if n_depth <= 0
            @warn "Maximum recursion depth reached during substitution. Possible infinite loop?"
            break
        end
    end

    return new_m
end




"""
_Recursive_ Symbolic Substitution of `MathExpr` with a Dict of Rules `input_rules`
---
Here both the key and value of the `input_rules::Dict{T,U}` support symbolic and numeric expressions.

The strategy is to first format the substitution rules to standard form `Dict{MathTerm,MathTerm}`, and then perform substitution _recursively_ (in a similar way as Mathematica's `ReplaceAll[]`).
"""
function subs(m::MathExpr, input_sub_rules::Dict{T,U}; lazy::Bool=false) where {T,U}
    formated_sub_rules = Dict{MathTerm,MathTerm}()
    for (k, v) in input_sub_rules
        formated_key = @match k begin
            ::MathExpr => k.content
            ::MathTerm => k
            ::Number => Num(k)
        end

        formated_value = @match v begin
            ::MathExpr => v.content
            ::MathTerm => v
            ::Number => Num(v)
        end

        formated_sub_rules[formated_key] = formated_value
    end

    # @show formated_sub_rules
    new_expr::MathExpr = replace_all(m.content, formated_sub_rules) |> MathExpr
    if lazy
        return new_expr
    else
        return evaluate(new_expr)
    end
end
# subs(m::Number, input_sub_rules::Dict{T,U}; lazy::Bool=false) where {T,U} = m
subs(A::AbstractArray{T,N}, input_sub_rules::Dict{U,V}; lazy::Bool=false) where {T,U,V,N} = map(x -> subs(x, input_sub_rules; lazy=lazy), A)

"Evaluation of a `MathTerm` Expression"
function evaluate(m::MathTerm)::Union{MathTerm,Number}
    @match m begin
        Num(x) => x
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
    eval_res = evaluate(x.content)
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
free_symbols(m::MathExpr) = free_symbols(m.content)
free_symbols(::Number) = Set{MathExpr}()

"get free symbol for `AbstractArray` (reduce from `free_symbols` of each element)"
free_symbols(A::AbstractArray) = mapreduce(free_symbols, ∪, A)
free_symbols(A::AbstractSparseArray) = free_symbols(A.nzval)
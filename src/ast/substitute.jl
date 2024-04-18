# ============================================================================================================================
# ====================================== Substitutions, Lambdification, and Evaluation =======================================
# ============================================================================================================================
"""
Substitute and evaluate expressions recursively.
"""
function _iterative_substitute(m::MathExpr, normalized_sub_rules::Dict{MathExpr,MathExpr})
    # Base case: direct match (for expression input)
    for (k, v) in normalized_sub_rules
        if m == k
            return v
        end
    end

    # Recursive case: apply substitution to sub-expressions
    @match m begin
        Var(var) => Var(var)
        UnaryTerm(op, arg) => UnaryTerm(op, _iterative_substitute(arg, normalized_sub_rules))
        BinaryTerm(op, left, right) => BinaryTerm(op, _iterative_substitute(left, normalized_sub_rules), _iterative_substitute(right, normalized_sub_rules))
    end
end

"""
Substitute Symbolic Expression with a Dict of Rules
---
Here the `input_rules` support symbolic, numeric, and even expressions.

The strategy is to first normalize the substitution rules to standard form `Dict{MathExpr,MathExpr}`, and then perform substitution recursively.
"""
function subs(m, input_sub_rules::Dict{T,U}; lazy::Bool=true) where {T,U}
    if m isa MathExpr
        # Normalize substitution rules
        normalized_sub_rules = Dict{MathExpr,MathExpr}()
        for (k, v) in input_sub_rules
            normalized_key = k isa MathExpr ? k : Var(k)
            normalized_value = v isa MathExpr ? v : Var(v)
            normalized_sub_rules[normalized_key] = normalized_value
        end

        new_m = _iterative_substitute(m, normalized_sub_rules)
        if lazy
            return new_m
        else
            return evaluate(new_m)
        end
    else
        return m # do nothing if `m` is not a MathExpr
    end
end


function evaluate(m::MathExpr)::Union{MathExpr,Number}
    if m isa MathExpr
        @match m begin
            Var(var) => begin
                if var isa Sym
                    return Var(var) # keep unchanged (cannot be evaluated)
                elseif var isa Number
                    return var
                end
            end
            UnaryTerm(op, arg) => (return (eval(op))(evaluate(arg)))
            BinaryTerm(op, left, right) => (return (eval(op))(evaluate(left), evaluate(right)))
        end
    else
        eval(m)
    end
end


"""
Get the Set of Free Symbols in an Expression
---
by recursive search
"""
function free_symbols(m)
    var_set = Set{Var}()
    if m isa MathExpr
        @match m begin
            Var(var) => begin
                # note: here `var` can either be a `Sym` or a `Number`
                if var isa Sym
                    push!(var_set, Var(var))
                end
            end
            UnaryTerm(op, arg) => begin
                var_set = var_set ∪ free_symbols(arg)
            end
            BinaryTerm(op, left, right) => begin
                var_set = var_set ∪ free_symbols(left) ∪ free_symbols(right)
            end
        end
    elseif m isa Array
        var_set = var_set ∪ free_symbols.(m)
    end
    return var_set
end
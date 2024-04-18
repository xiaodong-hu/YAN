# ============================================================================================================================
# =================================== Pre-defined and User-defined Math Operations ===========================================
# ============================================================================================================================
"""
Pre-defined Unary Operators
---
It can be changed with user-defined operators through `register_op`
# """
const UNARY_OP_SET = Set{Symbol}([
    # arithmetic functions
    :-,
    :inv,
    :abs,
    :real,
    :imag,
    :sqrt,
    # trigonometric functions
    :sin,
    :cos,
    :tan,
    :asin,
    :acos,
    :atan,
    :exp,
    :log,
    # linear algebra functions (require `using LinearAlgebra`)
    :det,
    :tr,
    :transpose,
    :hermitian,
    :adjoint,
    :eigen,
    :svd,
    :qr,
    :lu,
])


"""
Pre-defined Binary Operators
---
It can be changed with user-defined operators through `register_op`
"""
const BINARY_OP_SET = Set{Symbol}([
    :+,
    :-,
    :*,
    :/,
    ://,
    :^,
    :log,
])


# ============================================================================================================================
# ======================================== Operator Registration and Updates =================================================
# ============================================================================================================================
function register_op_to_global_method_table!(op::Symbol, nargs::Int64; module_name::Symbol=:Main)
    try
        println("  Importing Predefined Op ————————————————————————————— `$module_name.$op`")

        YAN.MLStyle.@match nargs begin
            1 => begin
                # eval(Meta.parse("($module_name.:($op))(x::T) where {T<:YAN.MathExpr} = YAN.UnaryTerm(Symbol($op), x)"))
                @eval ((YAN.$op)(x::YAN.MathExpr) = YAN.UnaryTerm(Symbol($op), x))
            end
            2 => begin
                # eval(Meta.parse("($module_name.:($op))(x::T, y::U) where {T<:YAN.MathExpr, U<:MathExpr} = YAN.BinaryTerm(Symbol($op), x, y)"))
                # eval(Meta.parse("($module_name.:($op))(x::T, y::U) where {T<:Number, U<:YAN.MathExpr} = YAN.BinaryTerm(Symbol($op), YAN.Var(x), y)"))
                # eval(Meta.parse("($module_name.:($op))(x::T, y::U) where {T<:YAN.MathExpr, U<:Number} = YAN.BinaryTerm(Symbol($op), x, YAN.Var(y))"))
                @eval (YAN.$op)(x::YAN.MathExpr, y::YAN.MathExpr) = YAN.BinaryTerm(Symbol($op), x, y)
                @eval (YAN.$op)(x::T, y::YAN.MathExpr) where {T<:Number} = YAN.BinaryTerm(Symbol($op), YAN.Var(x), y)
                @eval (YAN.$op)(x::YAN.MathExpr, y::T) where {T<:Number} = YAN.BinaryTerm(Symbol($op), x, YAN.Var(y))
            end
        end
        # eval(Meta.parse("export $op")) # export to `YAN` module
        @eval (export $op) # export to `YAN` module

        return (op, nargs)
    catch

        @warn "  Skipped: `$op` cannot be found in the method table of `$module_name`!"
    end
end



"""
Generate global method tables for predefined unary and binary operators
---
This should only be called at the beginning when the package is loaded.
"""
function initialize_global_method_table_for_pre_defined_op!()
    for pkg in YAN.MODULE_DEPENDENCE
        for op in YAN.UNARY_OP_SET
            if op in names(eval(pkg))
                register_op_to_global_method_table!(op, 1; module_name=pkg)
            end
        end
        for op in YAN.BINARY_OP_SET
            if op in names(eval(pkg))
                register_op_to_global_method_table!(op, 2; module_name=pkg)
            end
        end
    end
    return nothing
end


"""
Register a User-defined Operator and Update the Operator Table
---
Arguments:
- `op::Symbol`: the symbol representation of the user-defined operator
"""
function register_op(func::Function; module_name::Symbol=:Main)
    if string(getfield(first(methods(func)), :name))[1] == '#'
        error("Anonymous functions cannot be registered! Please define the function with an Explicit Name!")
    end
    nargs = (getfield(first(methods(func)), :nargs) - 1)

    # update the const operator table
    if Symbol(func) in names(eval(module_name))
        @match nargs begin
            1 => begin
                @eval push!(YAN.UNARY_OP_SET, Symbol($func))
            end
            2 => begin
                @eval push!(YAN.BINARY_OP_SET, Symbol($func))
            end
            _ => error("Now only unary and binary operators are supported!")
        end
    else
        @warn "Skipped! Operator `$func` is not defined in `$module_name`!"
    end
end
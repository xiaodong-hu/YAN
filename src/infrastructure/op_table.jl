# ============================================================================================================================
# =================================== Pre-defined and User-defined Math Operations ===========================================
# ============================================================================================================================
"""
Pre-defined Unary Operators
---
It can be changed with user-defined operators through `register_op`
# """
const UNARY_OP_SET = Set{Symbol}([
    # numeric type constructors
    :Real,
    # <: AbstractFloat
    :BigFloat,
    :Float64,
    :Float32,
    :Float16,
    # <: Integer
    :Bool,
    :BigInt,
    :Int128,
    :Int64,
    :Int32,
    :Int16,
    :Int8,
    :UInt128,
    :UInt64,
    :UInt32,
    :UInt16,
    :UInt8,
    # <: Complex (and :adjoint is defined)
    :Complex,
    :ComplexF64,
    :ComplexF32,
    :ComplexF16,

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
    :rad,
    :rad2deg,
    :anlge,
    :exp,
    :log,
    # linear algebra functions (require `using LinearAlgebra`)
    :norm,
    :det,
    :tr,
    :transpose,
    :hermitian,
    :Hermitian,
    :adjoint,
    :eigen,
    :svd,
    :qr,
    :lu,

    # # reserved key words
    # :hold,
    # :release_hold,
])


"""
Pre-defined Binary Operators
---
It can be changed with user-defined operators through `register_op`
"""
const BINARY_OP_SET = Set{Symbol}([
    # arithmetic functions
    :+,
    :-,
    :*,
    :/,
    ://,
    :^,
    # other functions
    :log,
    :atan,
])


# ============================================================================================================================
# ======================================== Operator Registration and Updates =================================================
# ============================================================================================================================
function register_op_to_global_method_table!(op::Symbol, nargs::Int64; module_name::Symbol=:Main)
    try
        println("  Importing Predefined Op ————————————————————————————— `$module_name.$op`")

        if nargs == 1
            # general case (without simplification)
            @eval (($module_name.$op)(x::YAN.MathExpr) = YAN.UnaryTerm(Symbol($op), x.repr) |> YAN.MathExpr)
            @eval (($module_name.$op)(x::YAN.MathTerm) = YAN.UnaryTerm(Symbol($op), x)) # we also need this for fast evaluation


        elseif nargs == 2
            # general case
            @eval (($module_name.$op)(x::YAN.MathExpr, y::YAN.MathExpr) = YAN.BinaryTerm(Symbol($op), x.repr, y.repr) |> YAN.MathExpr)
            @eval (($module_name.$op)(x::YAN.MathTerm, y::YAN.MathTerm)::YAN.MathTerm = YAN.BinaryTerm(Symbol($op), x, y)) # we also need this for fast evaluation

            @eval (($module_name.$op)(x::YAN.MathExpr, y::T) where {T<:Number} = YAN.BinaryTerm(Symbol($op), x.repr, YAN.Num(y)) |> YAN.MathExpr)
            @eval (($module_name.$op)(x::YAN.MathTerm, y::T) where {T<:Number} = YAN.BinaryTerm(Symbol($op), x, YAN.Num(y))) # we also need this for fast evaluation

            @eval (($module_name.$op)(x::T, y::YAN.MathExpr) where {T<:Number} = YAN.BinaryTerm(Symbol($op), YAN.Num(x), y.repr) |> YAN.MathExpr)
            @eval (($module_name.$op)(x::T, y::YAN.MathTerm) where {T<:Number} = YAN.BinaryTerm(Symbol($op), YAN.Num(x), y)) # we also need this for fast evaluation


            # Because `Base.^(::Number, ::Integer)` is already defined. we need to take extra efforts to avoid type ambiguities here (recall that we set `MathExpr<:Number`)
            if op == :^
                @eval (($module_name.$op)(x::YAN.MathExpr, y::T) where {T<:Integer} = ($module_name.$op)(x.repr, y) |> YAN.MathExpr)
                @eval (($module_name.$op)(x::YAN.MathTerm, y::T) where {T<:Integer} = YAN.BinaryTerm(Symbol($op), x, YAN.Num(y))) # we also need this for fast evaluation

                @eval (($module_name.$op)(x::YAN.MathExpr, y::T) where {T<:Number} = ($module_name.$op)(x.repr, y) |> YAN.MathExpr)
                @eval (($module_name.$op)(x::YAN.MathTerm, y::T) where {T<:Number} = YAN.BinaryTerm(Symbol($op), x, YAN.Num(y))) # we also need this for fast evaluation
            end
        end

        # specific for construction of AbstractArrray
        @eval Base.zero(::Type{YAN.MathExpr}) = YAN.MathExpr(Num(0))
        @eval Base.one(::Type{YAN.MathExpr}) = YAN.MathExpr(Num(1))


        # escape to `YAN` module
        @eval (export $op)

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
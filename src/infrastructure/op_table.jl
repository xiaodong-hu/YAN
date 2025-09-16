"""
Pre-defined Unary Operators
---
It can be modified with user-defined or user-redefined operators through `register_op!` method
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
    :-, # negative
    :inv,
    :abs,
    :real,
    :imag,
    :conj,
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
    :angle,
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
It can be modified with user-defined or user-redefined operators through `register_op!` method
"""
const BINARY_OP_SET = Set{Symbol}([
    # arithmetic functions
    :+,
    :-,
    :*,
    :/,
    ://,
    :^,
    :isless,
    # :(==),
    # other functions
    :log,
    :atan,
    :mod,
    :rem,
    :div,
    :gcd,
    :lcm,
    # linear algebra functions (require `using LinearAlgebra`)
    :dot,
    :cross,
])


"""
Register Pre-defined Operators to the Global Method Table
---
- Args:
    - `op::Symbol`: the operator to be registered
    - `nargs::Int64`: number of arguments of the operator (only support unary and binary operators now)
- Named Args:
    - `module_name::Symbol`: the module where the operator is defined (default is `:Main`, i.e., the `Main` module)
"""
function register_op_to_global_method_table!(op::Symbol, nargs::Int64; module_name::Symbol=:Main)
    # n_op_import = 0
    # try

    # catch
    #     @warn "  Skipped: `$op` cannot be found in the method table of `$module_name`!"
    # end

    # println("  Importing Predefined Op ————————————————————————————— `$module_name.$op`")

    if nargs == 1
        # general case (without simplification)
        @eval (($module_name.$op)(x::MathExpr) = UnaryTerm(Symbol($op), x.content) |> MathExpr)
        @eval (($module_name.$op)(x::MathTerm) = UnaryTerm(Symbol($op), x)) # we also need this for fast evaluation

        # specific for linear algebra, pre-define some basic arithmetic operators first
        if module_name == :LinearAlgebra
            for pre_required_op in (:+, :-, :*, :/, :^)
                @assert pre_required_op in BINARY_OP_SET
                @eval register_op_to_global_method_table!(Symbol($pre_required_op), 2; module_name=:Base) # we need these operators to be defined first
            end
        end
        if op == :det
            @eval (($module_name.$op)(A::AbstractMatrix{MathExpr})::MathExpr = sym_det(A))
        elseif op == :norm
            @eval (($module_name.$op)(x::AbstractArray{<:MathExpr}, p::Real=2)::MathExpr = sym_norm(x, p))
        end

    elseif nargs == 2
        # general case
        @eval (($module_name.$op)(x::MathExpr, y::MathExpr) = BinaryTerm(Symbol($op), x.content, y.content) |> MathExpr)
        @eval (($module_name.$op)(x::MathTerm, y::MathTerm)::MathTerm = BinaryTerm(Symbol($op), x, y)) # we also need this for fast evaluation

        @eval (($module_name.$op)(x::MathExpr, y::T) where {T<:Number} = BinaryTerm(Symbol($op), x.content, Num(y)) |> MathExpr)
        @eval (($module_name.$op)(x::MathTerm, y::T) where {T<:Number} = BinaryTerm(Symbol($op), x, Num(y))) # we also need this for fast evaluation

        @eval (($module_name.$op)(x::T, y::MathExpr) where {T<:Number} = BinaryTerm(Symbol($op), Num(x), y.content) |> MathExpr)
        @eval (($module_name.$op)(x::T, y::MathTerm) where {T<:Number} = BinaryTerm(Symbol($op), Num(x), y)) # we also need this for fast evaluation


        # Because `Base.^(::Number, ::Integer)` is already defined. we need to take extra efforts to avoid type ambiguities here (recall that we set `MathExpr<:Number`)
        if op == :^
            @eval (($module_name.$op)(x::MathExpr, y::T) where {T<:Integer} = ($module_name.$op)(x.content, y) |> MathExpr)
            @eval (($module_name.$op)(x::MathTerm, y::T) where {T<:Integer} = BinaryTerm(Symbol($op), x, Num(y))) # we also need this for fast evaluation

            @eval (($module_name.$op)(x::MathExpr, y::T) where {T<:Number} = ($module_name.$op)(x.content, y) |> MathExpr)
            @eval (($module_name.$op)(x::MathTerm, y::T) where {T<:Number} = BinaryTerm(Symbol($op), x, Num(y))) # we also need this for fast evaluation
        end
    end

    # specific for construction of boolean expressions
    # @eval Base.isless(x::MathExpr, y::Type{MathExpr}) = BinaryTerm(:<, x.content, y.content) |> MathExpr

    # specific for construction of AbstractArrray
    @eval Base.zero(::Type{MathExpr}) = MathExpr(Num(0))
    @eval Base.one(::Type{MathExpr}) = MathExpr(Num(1))


    # escape to `YAN` module
    @eval (export $op)

    # println("Importing Predefined Op... Done!")

    return (op, nargs)
end



"""
Load the Global Method Table for Pre-defined Operators
---
from `UNARY_OP_SET` and `BINARY_OP_SET`, to support easy construction of math expression with pre-defined oprators (such as `+`, `-`, `*`, `/`, etc.). 

This should be called at the beginning when the package is loaded.
"""
function load_global_method_table_for_pre_defined_op!()
    for pkg in MODULE_DEPENDENCE
        for op in UNARY_OP_SET
            if op in names(eval(pkg))
                register_op_to_global_method_table!(op, 1; module_name=pkg)
            end
        end
        for op in BINARY_OP_SET
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
- Args:
    - `func::Function`: the function to be registered
"""
function register_op!(func::Function; module_name::Symbol=:Main)
    if string(getfield(first(methods(func)), :name))[1] == '#'
        error("Check Input: Anonymous functions without an explicit name cannot be registered! Please define the function with an explicit name, rather than binding with a variable only!")
    end
    nargs = (getfield(first(methods(func)), :nargs) - 1)

    # update the const operator table
    if Symbol(func) in names(eval(module_name))
        @match nargs begin
            1 => begin
                @info "Registering Operator `$func` with $nargs arguments to `UNARY_OP_SET`..."
                @eval push!(UNARY_OP_SET, Symbol($func))
            end
            2 => begin
                @info "Registering Operator `$func` with $nargs arguments to `BINARY_OP_SET`..."
                @eval push!(BINARY_OP_SET, Symbol($func))
            end
            _ => error("Unimplemented: Now only unary and binary operators are supported!")
        end
    else
        @warn "Skipped! Operator `$func` is not defined in `$module_name`!"
    end
    @info "Done."
end

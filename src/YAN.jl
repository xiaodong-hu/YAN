module YAN

using MLStyle

"dependencies for help of declaration on symbolic function calls"
const MODULE_DEPENDENCE = [:Base, :LinearAlgebra]
for pkg in MODULE_DEPENDENCE
    @eval (using $pkg) # import dependency modules *within* `YAN`
end

export DEFAULT_SYM_DATATYPE, MODULE_DEPENDENCE, UNARY_OP_SET, BINARY_OP_SET
export Sym, Var, UnaryTerm, BinaryTerm, MathExpr
export sym, symtype, @vars, initialize_global_method_table_for_pre_defined_op!, register_op, subs, evaluate, free_symbols


# infrastructure
include("infrastructure/sym.jl")
include("infrastructure/expr.jl")
include("infrastructure/type_conversion_and_promotion.jl")
include("infrastructure/operator_table.jl")
# YAN.initialize_global_method_table_for_pre_defined_op!() # initialize the pre-defined operator table

# AST related
include("ast/substitute.jl")


# @eval (YAN.@vars x y z)


end # module
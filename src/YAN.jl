module YAN

using MLStyle, LinearAlgebra, SparseArrays

"dependencies for help of declaration on symbolic function calls"
const MODULE_DEPENDENCE = [:Base, :LinearAlgebra, :SparseArrays]
for pkg in MODULE_DEPENDENCE
    @eval (using $pkg) # import dependency modules *within* `YAN`
    # eval(pkg) # load dependency modules *within* `YAN`
end

export DEFAULT_SYM_DATATYPE, MODULE_DEPENDENCE, UNARY_OP_SET, BINARY_OP_SET
export Sym, Num, Var, UnaryTerm, BinaryTerm, MathTerm, MathExpr
export _sym, symtype, @vars, load_global_method_table_for_pre_defined_op!, register_op!, subs, evaluate, free_symbols


# infrastructure
include("infrastructure/sym_and_expr.jl")
include("infrastructure/symbolic_linear_algebra.jl")
include("infrastructure/op_table.jl")

# @info "Please Initialize Pre-defined Operator Table ..."
# YAN.load_global_method_table_for_pre_defined_op!() # initialize the pre-defined operator table

# AST related
include("ast/subs_and_eval.jl")


# @eval (YAN.@vars x y z)


end # module
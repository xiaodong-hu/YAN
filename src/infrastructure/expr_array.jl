# Scalar Symbolic Expression
struct MathExprArray{T,N} <: AbstractArray{T,N} where {T,N}
    data::Vector{MathExpr}
end
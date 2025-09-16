



sym_norm(x::AbstractArray{<:MathExpr}, p::Real=2)::MathExpr = sum(x -> abs(x)^p, x)^inv(p)



# @inline nterms(t) =
#     if iscall(t)
#         return reduce(+, map(nterms, arguments(t)), init=0)
#     else
#         return 1
#     end
# @inline _iszero(t::MathExpr) = @match t begin
#     MathExpr(Num(0)) => true
#     _ => false
# end
# """
# Soft Pivoting LU Decomposition for Matrix of MathExpr
# ---
# - Args:
#     - `A::AbstractMatrix{<:MathExpr}`: the input matrix
#     - `check::Bool=true`: whether to check the singularity of the matrix
# - Returns:
#     - `LU`: the LU factorization result
# """
# function sym_lu(A; check=true)
#     SINGULAR = typemax(Int)
#     m, n = size(A)
#     F = map(x -> x isa MathExpr ? x : Num(x), A)
#     minmn = min(m, n)
#     p = Vector{LinearAlgebra.BlasInt}(undef, minmn)
#     info = 0
#     for k = 1:minmn
#         kp = k
#         amin = SINGULAR
#         for i in k:m
#             absi = _iszero(F[i, k]) ? SINGULAR : nterms(F[i, k])
#             if absi < amin
#                 kp = i
#                 amin = absi
#             end
#         end

#         p[k] = kp

#         if amin == SINGULAR && !(amin isa Symbolic) && (amin isa Number) && iszero(info)
#             info = k
#         end

#         # swap
#         for j in 1:n
#             F[k, j], F[kp, j] = F[kp, j], F[k, j]
#         end

#         for i in k+1:m
#             F[i, k] = F[i, k] / F[k, k]
#         end
#         for j = k+1:n
#             for i in k+1:m
#                 F[i, j] = F[i, j] - F[i, k] * F[k, j]
#             end
#         end
#     end
#     check && LinearAlgebra.checknonsingular(info)
#     LU(F, p, convert(LinearAlgebra.BlasInt, info))
# end



@inline minor(A, j) = @view A[2:end, 1:size(A, 2).!=j] # the minor of A by removing the first row and j-th column
"""
Symbolic Determinant Function for Matrix of MathExpr
---
- Args:
    - `A::Matrix{<:MathExpr}`: the input square matrix
- Returns:
    - `MathExpr`: the symbolic evaluation of the input matrix
"""
function sym_det(A::Matrix{<:MathExpr})::MathExpr
    n = size(A, 1)
    @assert length(unique(size(A))) == 1 "Error: The input matrix must be square!"
    if n == 1
        return A[1, 1]
    elseif n == 2
        return A[1, 1] * A[2, 2] - A[1, 2] * A[2, 1]
    else
        return sum((-1)^(1 + j) * A[1, j] * sym_det(minor(A, j)) for j in axes(A, 2))
    end
end
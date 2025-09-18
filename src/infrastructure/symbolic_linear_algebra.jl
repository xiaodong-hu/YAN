
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
#     - `A::Matrix{<:MathExpr}`: the input matrix
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



minor(A, j::Int) = @view A[2:end, 1:size(A, 2).!=j] # the minor of A by removing the first row and j-th column
minor(A, i::Int, j::Int) = @view A[1:size(A, 1).!=i, 1:size(A, 2).!=j] # the minor of A by removing the i-th row and j-th column

"""
Symbolic Determinant of `Matrix{<:MathExpr}`
---
- Args:
    - `A::Matrix{<:MathExpr}`: the input square matrix
"""
function sym_det(A::AbstractMatrix{<:MathExpr})::MathExpr
    n = LinearAlgebra.checksquare(A) # check if A is square and get its size
    if n == 1
        return A[1, 1]
    elseif n == 2
        return A[1, 1] * A[2, 2] - A[1, 2] * A[2, 1]
    else
        return sum((-1)^(1 + j) * A[1, j] * sym_det(minor(A, j)) for j in axes(A, 2))
    end
end
"add method for transposed matrix"
sym_det(A::Transpose{MathExpr,Matrix{MathExpr}})::MathExpr = sym_det(A.parent) # use the original matrix to compute the determinant
"add method for adjointed matrix"
sym_det(A::Adjoint{MathExpr,Matrix{MathExpr}})::MathExpr = conj(sym_det(A.parent)) # use the original matrix to compute the determinant


"""
Symbolic Inverse of `Matrix{<:MathExpr}`
---
- Args:
    - `A::Matrix{<:MathExpr}`: the input square matrix
"""
function sym_inv(A::Matrix{<:MathExpr})::Matrix{MathExpr}
    n = LinearAlgebra.checksquare(A) # check if A is square and get its size
    adjA = Matrix{MathExpr}(undef, n, n) # the adjugate matrix (as the transpose of the cofactor matrix)
    detA_inv = 1 / sym_det(A)
    for i in 1:n, j in 1:n
        adjA[i, j] = (-1)^(i + j) * sym_det(minor(A, j, i)) # note the transpose here
    end
    return detA_inv * adjA
end
sym_inv(A::StridedMatrix{<:MathExpr})::Matrix{MathExpr} = sym_inv(A)



"""
Symbolic Transpose of `Matrix{<:MathExpr}`
"""
function sym_transpose(A::Matrix{<:MathExpr})::Matrix{MathExpr}
    res = Matrix{MathExpr}(undef, size(A))
    for i in axes(A, 1), j in axes(A, 2)
        res[j, i] = A[i, j]
    end
    return res
end

"""
Symbolic Adjoint of `Matrix{<:MathExpr}`
"""
function sym_adjoint(A::Matrix{<:MathExpr})::Matrix{MathExpr}
    return sym_transpose(conj.(A))
end

"""
Symbolic Dot Product of Two `Vector{T}` and `Vector{U}`
"""
sym_dot(A::Vector{T}, B::Vector{U}) where {T,U} = @inbounds sum(conj(A[i]) * B[i] for i in axes(A, 1))
# sym_dot(A::Vector{T}, B::Vector{MathExpr}) where T = @inbounds sum(conj(A[i]) * B[i] for i in axes(A, 1)) |> MathExpr
# sym_dot(A::Vector{MathExpr}, B::Vector{T}) where T = @inbounds sum(conj(A[i]) * B[i] for i in axes(A, 1)) |> MathExpr


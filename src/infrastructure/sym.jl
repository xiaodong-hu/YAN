const DEFAULT_SYM_DATATYPE::Type = Float64 # concrete type is preferred!

"""
Basic Struct `Sym{T}` as the Data Structure of Symbolic Variable
---
fields:
- `ref::Ref{String}`: reference to the variable name

We only store the reference (of the same size as `UInt8`) to the variable name, not the value itself for memory efficiency.
"""
mutable struct Sym{T}
    ref::Ref{String} # reference to the variable name
end
Base.show(io::IO, s::Sym) = print(io, s.ref[])

"simple *internal* constructor for symbolic variables"
_sym(x, T::Type) = Sym{T}(Ref(string(x)))
_sym(x::T) where {T<:Number} = Sym{typeof(x)}(Ref(string(x)))


"helper function to extract datatype of a symbolic variable"
symtype(::Sym{T}) where {T} = T
symtype(x) = typeof(x)


"""
Macro to Declare Multiple Symbolic Variables `<: MathExpr`, with Optional Type Annotations
---
Example usage:
```julia
@vars x y::UInt32 z::Matrix{ComplexF64} # declare `x` as Float64, `y` as UInt32, and `z` as Matrix{ComplexF64}
```
If type is not specified, the default type is used.
"""
macro vars(ex...)
    exprs = Expr(:block)  # Initialize an expression block to hold all declarations
    for item in ex
        if isa(item, Expr) && item.head == :(::) && isa(item.args[1], Symbol) # if with type annotations
            var_name = item.args[1]
            var_type = item.args[2]
            # Create a Sym of the specified type, wrap it in Var, and assign it to var_name
            new_var_expr = :($(esc(var_name)) = Var(_sym($(string(var_name)), $(esc(var_type)))))
        elseif isa(item, Symbol)
            # Create a Sym with the default type, wrap it in Var, and assign it to var_name
            new_var_expr = :($(esc(item)) = Var(_sym($(string(item)), DEFAULT_SYM_DATATYPE)))
        else
            error("Invalid argument to @vars. Expect symbols or type annotations.")
        end
        push!(exprs.args, new_var_expr)
    end
    return exprs
end

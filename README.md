# `YAN.jl`

Neat and Fast Julia Package for Symbolic Computation.

`YAN.jl` is a julia package for construction and AST transformation on symbolic mathematical expressions. YAN is named for Chinese character 「演」, which means *transformation*, corresponding to AST transformation of math expression, and Chinese character 「衍」, which means *infinity* (和之以天倪，因之以曼衍 —— 「庄子·齐物论」), corresponding to the infinite capability of the symbolic expressions.

## Usage
Bare package `YAN` DO NOT register any pre-defined operators for flexibility, which means you can use it to construct basic algebraic structure which is even not a ring or or module. Complicated relations such as non-commutative algebras can also be constructed.

But for most-people usage, basic arithmetic operations as well as symbolic linear algebra functions is recommonded to be registered, maintained in `UNARY_OP_SET` and `BINARY_OP_SET`
```julia
using YAN

# (for most people) run below immediately once `YAN` is used
initialize_global_method_table_for_pre_defined_op!() # all pre-defined operators in `UNARY_OP_SET` and `BINARY_OP_SET` are defined for MathExpr
```

### Variable Claim (with Optional Type Annotations)

```julia
struct my_datatype{T} end # user-defined datatype (see below)

# Variable Claim (with Optional Type Annotations)
@vars x y::Int64 z::my_datatype

@assert symtype(x) == Float64 # without type annotation `DEFAULT_SYM_DATATYPE` is assigned for variables, which is `Float64` by defaut
@assert symtype(y) == Int64
@assert symtype(z) isa my_datatype
```

### Substitution and Evaluation 
Substitution is not lazy by default. But it can be **literal**, i.e. **lazy without any evaluation**, even for numerical parts like `1 * 2`.
```julia 
# scalar substitution to symbolic expression
ex = sin(x) * y / (exp(im * z) + 1)^x
@test subs(ex, Dict(x => y, y => z, z => x)) == sin(y) * z / (exp(im * x) + 1)^y

# scalar substitution to numerical result (with evaluation)
ex = x^x
@test subs(ex, Dict(x => 0); lazy=true) |> evaluate == 1

# array substitution to symbolic expression
ex = [sin(x) 1-cos(y); x^tan(z) 2*x]
@test subs.(ex, Ref(Dict(1 => x, x => y, y => z, z => x))) == [sin(y) x-cos(z); y^tan(x) 2*y] # Note: even 1 is replaced!

# array substitution to numerical result (with evaluation)
ex = [x x+1; x^2 1//x]
@test subs.(ex, Ref(Dict(x => 2))) .|> evaluate == [2 3; 4 1//2]
```

## Benchmark
Symbolic substituion and evaluation on huge 100*100 matrix of form $A_{ij}=\sin(ix+jy)$ and of assignment $x=1, y=2$
```julia
using YAN, BenchmarkTools

@btime begin
    YAN.@vars x y
    test_array = Matrix{YAN.MathExpr}(undef, 100, 100)
    for i in 1:100, j in 1:100
        test_array[i, j] = sin(i * x + j * y)
    end
    ex = YAN.subs.(test_array, Ref(Dict(x => 1, y => 2)); lazy=false)
end
```
finishes in `27.643 ms (590128 allocations: 20.14 MiB)` in a single thread of `13th Gen Intel i7-1365U` on my laptop.


## Pre-defined Operators
The operator set can be changed with user-defined operators through method `register_op(::Symbol)`
```julia
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

    # reserved key words
    :hold,
    :release_hold,
])

const BINARY_OP_SET = Set{Symbol}([
    # # boolean function
    # :(==),
    # arithmetic functions
    :+,
    :-,
    :*,
    :/,
    ://,
    :^,
    # other functions
    :log,
    :atan
])
```

### Registration of User-defined Operators (todo!)
```julia
function my_func(x)
    (x,x)
end

register_op(:my_func) # register to `UNARY_OP_SET`
@assert :my_func in UNARY_OP_SET

# todo for for symbols that are not defined yet
```

## Todo

1. add registration of undefined functions
2. add `hold` and `release_hold` like Mathematica 
3. add support for simplication rules
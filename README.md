# `YAN.jl`

Neat and Fast Julia Package for Symbolic Computation.

`YAN.jl` is a julia package for construction and *fast* AST transformation on **Symbolic Mathematical Expressions**. YAN is named for Chinese character 「演」, which means *transformation*, and Chinese character 「衍」, which means *infinity* (和之以天倪，因之以曼衍 —— 「庄子·齐物论」).

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

### Registration User-defined Operators
```julia
function my_func(x)
    (x,x)
end

register_op(:my_func) # register to `UNARY_OP_SET`
@assert :my_func in UNARY_OP_SET
```

### Substitution and Evaluation 
```julia 
# scalar substitution to symbolic expression
ex = sin(x) * y / (exp(im * z) + 1)^x
@assert subs(ex, Dict(x => y, y => z, z => x)) == sin(y) * z / (exp(im * x) + 1)^y

# scalar substitution to numerical result (with evaluation)
ex = x^x
@assert  subs(ex, Dict(x => 0)) |> evaluate == 1
ex = x^x^x
@assert  subs(ex, Dict(x => 0)) |> evaluate == 0

# array substitution to symbolic expression
ex = [sin(x) 1-cos(y); x^tan(z) 2*x]
@assert  subs.(ex, Ref(Dict(1 => x, x => y, y => z, z => x))) == [sin(y) x-cos(z); y^tan(x) 2*y] # Note: even 1 is replaced!

# array substitution to numerical result (with evaluation)
ex = [x x+1; x^2 1//x]
@assert subs.(ex, Ref(Dict(x=>2))) .|> evaluate == [2 3; 4 1//2]
```

## Benchmark



## Pre-defined Operators


## Todo list

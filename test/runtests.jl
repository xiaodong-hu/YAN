using Test
using YAN
YAN.initialize_global_method_table_for_pre_defined_op!()

struct User_Defined_Datatype{T} end

@testset "Variables Definition with (Parametric) Type Annotations" begin
    YAN.@vars x y z::Float64 A::Matrix{ComplexF64} B::User_Defined_Datatype

    @test YAN.symtype(x) == YAN.DEFAULT_SYM_DATATYPE
    @test YAN.symtype(y) == YAN.DEFAULT_SYM_DATATYPE
    @test YAN.symtype(z) == Float64
    @test YAN.symtype(A) == Matrix{ComplexF64}
    @test YAN.symtype(B) == User_Defined_Datatype
end

@testset "Operator Table Initialization and Registration" begin
    YAN.@vars x y
    my_func_unary(x) = x + 1
    my_func_binary(x, y) = x * y
    YAN.register_op(my_func_unary) # this should be warned "skipped" since `my_func_unary` is defined locally
    YAN.register_op(my_func_binary) # this should be warned "skipped" since `my_func_binary` is defined locally

    @test my_func_unary(x) == x + 1
    @test my_func_binary(x, x) == x * x
    @test :my_func_unary ∉ names(Main)
    @test :my_func_binary ∉ names(Main)
end

@testset "Substitution and Evaluation" begin
    YAN.@vars x y z

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
end




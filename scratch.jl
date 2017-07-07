@enum GENDER MALE=1 FEMALE=2

type MyType{T<:AbstractFloat}
    a::T
end

type MyAmbType
    a::AbstractFloat
end

type UpdatedHuman
    a::Int64
    b::GENDER
end

m = MyType(3.2)
t = MyAmbType(3.2)
h = UpdatedHuman(1, FEMALE)

typeof(m)
typeof(t)

func(m::MyType) = m.a+1
funct(t::MyAmbType) = t.a + 1
funch(h::UpdatedHuman) = h.a + 1

@code_llvm  funch(h)

#code_llvm(func,Tuple{MyType{Float64}})
#code_llvm(func,Tuple{MyType{AbstractFloat}})
#code_llvm(func,Tuple{MyType})


# define i64 @julia_funch_70946(%jl_value_t*) #0 {
# top:
#   %1 = bitcast %jl_value_t* %0 to i64*
#   %2 = load i64, i64* %1, align 16
#   %3 = add i64 %2, 1
#   ret i64 %3
# }
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


using DataArrays, DataFrames
costs1 = DataFrame(simid = Int64[], ID = Int64[], ageofonset = Int64[], yearofonset = Int64[], typeofdisease = Int64[],physiciancost = Int64[], hospitalcost = Int64[], medivaccost = Int64[], seqmajor = Int64[], seqminor = Int64[], seqmajor = Int64[] )

for i = 1:1000
push!(costs1, vcat([11,1, 1, 1, 1], [1, 1, 1, 1, 1]))
end

push!(costs1, [11, 1, 2, 3, 4, 5, 6, 7, 8, 9])

costs2 = DataFrame(simid = Int64[], ID = Int64[], ageofonset = Int64[], yearofonset = Int64[], typeofdisease = Int64[],physiciancost = Int64[], hospitalcost = Int64[], medivaccost = Int64[], seqmajor = Int64[], seqminor = Int64[], seqmajor = Int64[] )

for i = 1:1000
    push!(costs2, vcat([12,1, 1, 1, 1], [1, 1, 1, 1, 1]))
end

push!(costs2, [12, 1, 2, 3, 4, 5, 6, 7, 8, 9])

a = [costs1, costs2] ## array --- results from our pmap
[vcat(a[i]) for i =1:2]
vcat(a) ## v-concatenates them all. 

costs[findin(costs[:ID], 3), :]


function A()
    newarray = zeros(Int64, 200)
    r = B(newarray)
    return r
end

function B(i)
    i[1] = 2
    return i
end



hosts = @parallel for i=1:96
    println(run(`hostname`))
end


#http://white.ucc.asn.au/2017/08/17/starting-workers.html
@eval Base.Distributed import Base.warn_once
addprocs([("node001", 32), ("node002", 32), ("node003", 32), ("node004", 32), ("node006", 32)])

addprocs([("node001", 32), ("node002", 32), ("node003", 32), ("node004", 32)])
addprocs([("node001", 32)])

open("sherlock", "w") do f
    for host in [string("node", lpad(i, 3, 0)) for i = 10:15]
        for i = 1:32
            write(f, "$host\n")
        end
    end       
end
## GPU kernels
#http://mikeinnes.github.io/2017/08/24/cudanative.html


#http://www.stochasticlifestyle.com/multi-node-parallelism-in-julia-on-an-hpc/
## a possible slurm script
        #!/bin/bash
        #SBATCH -A <account>
        #SBATCH --job-name="juliaTest"
        #SBATCH --output="juliaTest.%j.%N.out"
        #SBATCH --partition=compute
        #SBATCH --nodes=8
        #SBATCH --export=ALL
        #SBATCH --ntasks-per-node=24
        #SBATCH -t 01:00:00
        export SLURM_NODEFILE=`generate_pbs_nodefile`
        ./julia --machinefile $SLURM_NODEFILE /home/crackauc/test.jl

# some more slurm scripts
#https://github.com/iancze/ParallelTest.jl


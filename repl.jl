
# if abm

#   data = runmain_parallel(n) ## data contains tuples(Human, DC) returned from main - FOR EACH SIMULATION
# else 
#   include("main.jl")
# end

using Lumberjack
add_truck(LumberjackTruck("processrun.log"), "my-file-logger")
remove_truck("console")

addprocs(50)
@everywhere include("main.jl")


function readjld(prefix)
  info("starting reading of hdf5/jld files using pmap")
  a = pmap(1:numofsims) do x
    filename = string(prefix, x, ".jld")
    return load(filename)["DC"]  
  end
  info("pmap finished, returning function. ")
  return a;
end

function fullrun()
  info("starting full run: seed + pastthirty with/without vaccine")
  info("total number of processors setup: $(nprocs())")
  info("setting up Hia and Model parameters...")
  @everywhere P = HiaParameters(simtime = 30*365, vaccinetime = 10*365)
  @everywhere M = ModelParameters(numofsims = 500)
  info("\n $P"); info("\n $M"); info("\n")
  if M.savejld 
    info("savejld is turned on, save folder set to $(M.write_serialdatalocation)")
    if !isdir(M.write_serialdatalocation) 
        info("save folder not found, attemping to make directory")
        mkdir(M.write_serialdatalocation)
    end
  end
  info("starting seed pmap...")
  resultsseed = pmap((cb, x) -> seed(x, P, M, cb), Progress(M.numofsims*P.simtime), 1:(M.numofsims), passcallback=true)   
  info("seed finished!")

  info("starting pastthirty simulations")
  if P.vaccinetime == 0 
    info("vaccine time is set to zero... exiting")
    throw("P.vaccinetime is zero.")
  end  
  info("extra runtime is set to $(P.vaccinetime)")
  info("jld read folder set to $(M.read_serialdatalocation)")  # "/stor4/share/affan/serial_july1/"
    
  info("starting pastthirty pmap with M.vaccineon status: $(M.vaccineon)...")
  resultsone = pmap((cb, x) -> pastthirty(x, P, M, cb), Progress(M.numofsims*P.vaccinetime), 1:(M.numofsims), passcallback=true) 
  info("extrathirty finished")     
  info("flipping M.vaccine status for rerun")
  M.vaccineon = !M.vaccineon
  info("starting pastthirty pmap with vaccineon status: $(M.vaccineon)...")
  resultstwo = pmap((cb, x) -> pastthirty(x, P, M, cb), Progress(M.numofsims*P.vaccinetime), 1:(M.numofsims), passcallback=true)    
  info("extrathirty finished")     
  info("all simulation scenarios finished!")

  return resultsseed, resultsone, resultstwo

end

fullrun()

# P = HiaParameters(simtime = 30*365, vaccinetime = 10*365, betaone = 0.5, betatwo = 0.5, betathree=0.5, betafour = 0.5)
#main(50)
#process(500, "./serial/hser")
#process(500, "./serial/vhser")
#process(500, "./serial/nvhser")



    # ## group counts - columns represent group sizes
    # grpcnts = zeros(Int64, numofsims, 5)
    # for i = 1:length(results)      
    #   h = results[i][1] 
    #   grpcnts[i, 1] = length(find(x -> x.agegroup_beta == 1, h))
    #   grpcnts[i, 2] = length(find(x -> x.agegroup_beta == 2, h))
    #   grpcnts[i, 3] = length(find(x -> x.agegroup_beta == 3, h))
    #   grpcnts[i, 4] = length(find(x -> x.agegroup_beta == 4, h))
    #   grpcnts[i, 5] = length(find(x -> x.agegroup_beta == 5, h))
    # end
    # writedlm(string("groupcounts.dat"), grpcnts)

#include("main.jl")
#P = HiaParameters(simtime = 1*365,vaccinetime = 0, betaone=0.9, betatwo=0.9, betathree=0.9, betafour = 0.9)
#main(1, P, n -> 1)
 

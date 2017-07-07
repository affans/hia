using Parameters
using Match
using Distributions
using StatsBase
using ParallelDataTransfer
using DataArrays, DataFrames
using ProgressMeter
using PmapProgressMeter
using JLD

# if abm

#   data = runmain_parallel(n) ## data contains tuples(Human, DC) returned from main - FOR EACH SIMULATION
# else 
#   include("main.jl")
# end

using Lumberjack
add_truck(LumberjackTruck("processrun.log"), "my-file-logger")
remove_truck("console")

info("starting lumberjack process, starting repl")
info("adding procs...")
info("starting @everywhere include process...")

addprocs(4)
@everywhere include("main.jl")

function fullrun()
  info(now())
  info("starting full run: seed + pastthirty with/without vaccine")
  info("total number of processors setup: $(nprocs())")
  info("setting up Hia and Model parameters...")
  @everywhere P = HiaParameters(simtime = 1*365, vaccinetime = 1*365)
  @everywhere M = ModelParameters(numofsims = 8)
  info("\n $P"); info("\n $M");
  
  info("starting seed pmap...")
  resultsseed = pmap((cb, x) -> sim(x, P, M, cb), Progress(M.numofsims*P.simtime), 1:(M.numofsims), passcallback=true)   
  info("seed finished!")

  if M.savejld 
    info("M.savejld is true, checking if $(M.writeloc) exists")
    if !isdir(M.writeloc) 
        info("...not found: attemping to make directory $(M.writeloc)")
        try
          mkdir(M.writeloc)
        catch
          info("count not create jld save directory")
          error("could not create jld save directory")
        end
    end
    info("writing files...")
    for i=1:length(resultsseed)
      hf = string(M.writeloc, "seed$i.jld")    
      save(hf, "humans", resultsseed[i][1], "DC", resultsseed[i][2])    
    end    
  else 
    info("this is a full run, save jld must be on")
    error("savejld not on")
  end
  info("starting past seed simulations")
  if P.vaccinetime == 0 
    info("vaccine time is set to zero... exiting")
    throw("P.vaccinetime is zero.")
  end  
  info("extra runtime is set to $(P.vaccinetime)")
  info("jld read folder set to $(M.readloc)")  
  
  @everywhere M.initializenew = false
  info("M.initialize variable set to $(M.initializenew)")
  info("starting pastthirty pmap with M.vaccineon status: $(M.vaccineon)...")  
  @everywhere P.simtime = P.vaccinetime
  resultsone = pmap((cb, x) -> sim(x, P, M, cb), Progress(M.numofsims*P.simtime), 1:(M.numofsims), passcallback=true)  
  info("... finished")     
  info("flipping M.vaccine status for rerun")
  @everywhere M.vaccineon = !M.vaccineon
  info("starting pastthirty pmap with vaccineon status: $(M.vaccineon)...")
  resultstwo = pmap((cb, x) -> sim(x, P, M, cb), Progress(M.numofsims*P.simtime), 1:(M.numofsims), passcallback=true)    
  info("... finished")     
  info("all simulation scenarios finished!")
  return resultsseed, resultsone, resultstwo
end

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
 

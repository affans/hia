using Parameters
using Match
using Distributions
using StatsBase
using ParallelDataTransfer
using DataArrays, DataFrames
using ProgressMeter
using PmapProgressMeter
using JLD2
using Lumberjack

# Pkg.add("Parameters")
# Pkg.add("Match")
# Pkg.add("Distributions")
# Pkg.add("StatsBase")
# Pkg.add("DataFrames") ## adds DataArrays
# Pkg.add("ProgressMeter")
# Pkg.add("ParallelDataTransfer")
# Pkg.add("Lumberjack")
# Pkg.clone("https://github.com/simonster/JLD2.jl")
# Pkg.clone("https://github.com/slundberg/PmapProgressMeter.jl")

add_truck(LumberjackTruck("processrun.log"), "my-file-logger")
remove_truck("console")

info("starting lumberjack process, starting repl")
info("adding procs...")
info("starting @everywhere include process...")

addprocs(60)
@everywhere include("main.jl")

function filestructure(P::HiaParameters, M::ModelParameters)  
  if !isdir(M.writeloc) 
      info("...not found: attemping to make directory $(M.writeloc)")
      try
        mkdir(M.writeloc)
        info("done")
      catch
        info("count not create jld save directory")
      end
  end
end

function seed()
  info(now())
  simhash = string(hash(time()))
  info("starting seed...")
  info("total number of processors setup: $(nprocs())") 
  info("setting up Hia and Model parameters...")
  @everywhere P = HiaParameters(simtime = 30*365, vaccinetime = 10*365)
  @everywhere M = ModelParameters(numofsims = 500, vaccineon=false, savejld = false)  ## start with vaccine off
  filestructure(P, M)
  info("\n $P"); info("\n $M");
  info("starting seed pmap...")
  rs = pmap((cb, x) -> sim(x, P, M, cb), Progress(M.numofsims*P.simtime), 1:(M.numofsims), passcallback=true)
  info("pmap finished!")

  ## rs[i][1] contains the "human" array
  ## rs[i][2] contains the costs dataframe
  ## rs[i][3] contains version2 of datacollection -- change this if removing the old one.

  ## august 10 update: removed the DC part of it - recover that if needed

  if M.savejld    
    info("writing JLD files...")
    for i=1:M.numofsims
      hf = string(M.writeloc, "seed$i.jld")    
      @save hf rs[i][1]
    end    
  end

  info("Processing Costs...")    
  costs = [rs[i][2] for i = 1:M.numofsims]
  writetable("costs.dat", vcat(costs))           

  dcc = [rs[i][3] for i = 1:M.numofsims]     
  writetable("dcc.dat", vcat(dcc))
  return rs
end


function pastthirty()
  info("starting pastthirty simulations")
  
  info("setting up Hia and Model parameters...")
  @everywhere P = HiaParameters(simtime = 10*365, vaccinetime = 10*365)
  @everywhere M = ModelParameters(numofsims = 50)  ## start with vaccine off
  

  @everywhere M.vaccineon = false       ## the first set of results with vaccine off
  @everywhere M.initializenew = false   ## make sure we dont initialize a new set of humans
  @everywhere P.simtime = P.vaccinetime ## since sim() only looks at P.simtime

  info("\n $P"); info("\n $M");
  info("from processor $(myid()), model parameters are...")
  info("extra runtime is set to $(P.vaccinetime)")
  info("jld read folder set to $(M.readloc)")  
  info("M.initialize variable set to $(M.initializenew)")

  info("starting pastthirty pmap with vaccine status: $(M.vaccineon)...")    
  resultsone = pmap((cb, x) -> sim(x, P, M, cb), Progress(M.numofsims*P.simtime), 1:(M.numofsims), passcallback=true)  
  info("... finished")     

  info("flipping M.vaccine status for rerun")
  @everywhere M.vaccineon = !M.vaccineon
  info("starting pastthirty pmap with vaccine status: $(M.vaccineon)...")
  resultstwo = pmap((cb, x) -> sim(x, P, M, cb), Progress(M.numofsims*P.simtime), 1:(M.numofsims), passcallback=true)    
  info("... finished")     

  info("writing results one and two files...")
  for i=1:M.numofsims
    rs1 = string(M.writeloc, "one$i.jld")    
    rs2 = string(M.writeloc, "two$i.jld")        
    save(rs1, "humans", resultsone[i][1], "DC", resultsone[i][2], "costs", resultsone[i][3])    
    save(rs2, "humans", resultstwo[i][1], "DC", resultstwo[i][2], "costs", resultstwo[i][3])        
  end   
  info("all simulation scenarios finished!")
  return resultsseed, resultsone, resultstwo
end
r = seed()


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
 

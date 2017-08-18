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
using FileIO

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
  else 
      info("serial write location already exists")
  end
end

function seed()
  info(now())
  simhash = string(hash(time()))
  info("starting seed...")
  info("total number of processors setup: $(nprocs())") 
  info("setting up Hia and Model parameters...")
  @everywhere P = HiaParameters(simtime = 10*365)
  @everywhere M = ModelParameters(numofsims = 500, initializenew = false, vaccineon=false, savejld=false)  ## start with vaccine off
  filestructure(P, M)
  info("\n $P"); info("\n $M");
  info("starting seed pmap...")
  rs = pmap((cb, x) -> sim(x, P, M, cb), Progress(M.numofsims*P.simtime), 1:(M.numofsims), passcallback=true)
  info("pmap finished!")

  ## rs[i][1] the "human" array
  ## rs[i][2] costs 
  ## rs[i][3] incidence
  ## rs[i][4] vaccine

  if M.savejld    
    info("writing JLD files...")
    for i=1:M.numofsims
      hf = string(M.writeloc, "seed$i.jld2")    
      @save hf rs[i][1]
    end    
  end

  info("Processing Costs...")    
  costs = [rs[i][2] for i = 1:M.numofsims]
  writetable("costs.dat", vcat(costs)) 
  info("...finished!")          

  info("Processing DCC...")   
  dcc = [rs[i][3] for i = 1:M.numofsims]     
  writetable("dcc.dat", vcat(dcc))
  info("...finished!")  
  
  if M.vaccineon
      info("Processing vaccine...")   
      vac = [rs[i][4] for i = 1:M.numofsims]     
      writetable("vac.dat", vcat(vac))
      info("...finished!")  
  end
  return rs
end
r = seed()

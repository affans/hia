include("SlurmConnect.jl")
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
info("lumberjack process started up, starting repl")

info("adding procs...")
#@eval Base.Distributed import Base.warn_once
#addprocs([("node001", 32), ("node002", 32), ("node003", 32), ("node004", 32), ("node005", 32), ("node006", 32), ("node007", 32),("node008", 32), ("node010", 32),("node011", 32),("node012", 32),("node013", 32),("node014", 32),("node016", 32),("node017", 32), ("node018", 32)])

s = SlurmManager(512)
@eval Base.Distributed import Base.warn_once
addprocs(s, partition="defq", N=16)


println("added $(nworkers()) processors")
info("starting @everywhere include process...")
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

function printmodel(P::HiaParameters, M::ModelParameters)
  if M.savejld == false
    info("savejld is set to false, will not save jld files")
    info("read location is set to $(M.readloc)")
  else 
    info("savejld is set to true, will save jld files")
    info("write location is set to $(M.writeloc)")
  end

  if P.lfreductiononoff == 0
    info("lifetime reduction is off - max reduction is set to 0")
  else
    info("lifetime reduction is on --")
  end

end

function seed()
  info(now())
  simhash = string(hash(time()))
  info("starting seed...")
  info("total number of processors setup: $(nprocs())") 
  info("setting up Hia and Model parameters...")

  ## model parameters
    ## when changing lfreductiononoff, MAKE SURE THE RIGHT BETAS ARE USED. 
  @everywhere P = HiaParameters(simtime = 10*365, lfreductiononoff = 1, primarycoverage=0.77)
  @everywhere M = ModelParameters(initializenew = false, vaccineon=true, savejld=false)  
  ## if initializenew == false, seed data(ie first thirty years) must be given
  M.writeloc = "/data/sep05/serial_wilf/"
  M.readloc  = "/data/sep05/serial_wilf/"
  filestructure(P, M)
  printmodel(P, M)
  info("\n $P"); info("\n $M");
  info("starting seed pmap...")
  rs = pmap((cb, x) -> sim(x, P, M, cb), Progress(M.numofsims*P.simtime), 1:(M.numofsims), passcallback=true)
  println("pmap finished")
  
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
  return nothing
end
r = seed();


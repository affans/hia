
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

function runseed(numberofsims, P::HiaParameters)
    info("runseed(): running seed simulations, count = $numberofsims... ")    
    if P.vaccinetime > 0 
        info("runseed(): vaccine time is turned on; only seed simulations; vaccine scenario will not be run")
    end
    info("runseed(): starting pmap/seed() with above parameters...")
    results = pmap((cb, x) -> seed(x, P, cb), Progress(numberofsims*P.simtime), 1:numberofsims, passcallback=true)   
    ## process results. 
    info("runseed(): finished!")
end

function runpastthirty(numberofsims, vaccineon, P::HiaParameters)
    info("runpastthirty(): running pastthirty simulations, see parameters above")
    info("runpastthirty(): vaccine on? ($vaccineon)")
    if P.vaccinetime == 0 
      info("runpastthirty(): vaccine time is set to zero... exiting")
      throw("P.vaccinetime is zero.")
    end    
    info("runpastthirty(): starting pmap/pastthirty() with above parameters...")
    results = pmap((cb, x) -> pastthirty(x, vaccineon, P, cb), Progress(numberofsims*P.vaccinetime), 1:numberofsims, passcallback=true)   
    info("runpastthirty(): finished, returning results!")    
    return results
end



function readjld(numofsims, prefix)
  ## this files reads all the serialized datacollection files from a folder
  ## and returns an array with these -- can be sent to process_dc()  
  ## prefix in the form of "./serial/(v)(nv)(h)ser.jld"
  info("process(): running processing for number of sims: $numofsims")
  info("process(): ... see method for description")  
  info("process(): uses pmap, how many procs? $(nprocs())")
  info("process(): prcessing prefix: $prefix")  
  info("process(): starting reading of hdf5/jld files using pmap")
  a = pmap(1:numofsims) do x
    filename = string(prefix, x, ".jld")
    return load(filename)["DC"]  
  end
  info("process(): pmap finished, all files are loaded into memory... function has returned. ")
  return a;
end

function processresults(results)
    ## This function accepts an array of DataCollection types - ie, Array{DataCollection}. Each element in this array corresponds to a datacollection object for each simulation. 

    ## Returns: Creates 5 folders for each agegroup, and for each folder, the datafiles for each disease class is created. 
    ## For example, in latent.dat the rows correspond to the number of days in the simulation, and the columns represents the simulations. 

    numofsims = length(results)         ## this gives the number of simulations
    numofdays = size(results[1].lat, 1) ## this gives the number of days (we pick the latent counter from the first simulation to get this.. )

    info("processing results")
    for agegroup = 1:5
      info("...processing agegroup: $agegroup")
      ## create matrices, for each data collection variable to put the simulation results. 
      ## matrix is numberofdays x numberofsims -- ie, each column represents a simulation
      lm = Matrix{Int64}(numofdays, numofsims)  
      cm = Matrix{Int64}(numofdays, numofsims)
      sm = Matrix{Int64}(numofdays, numofsims)
      im = Matrix{Int64}(numofdays, numofsims)
      rm = Matrix{Int64}(numofdays, numofsims)    
      dn = Matrix{Int64}(numofdays, numofsims) ## dead natural
      di = Matrix{Int64}(numofdays, numofsims) ## dead invasive
      
     
      for i = 1:length(results)  # for each simulation
        dc = results[i]  ## get the i'th simulation results. 
        @unpack lat, car, sym, inv, rec, deadn, deadi = dc ## unpack datacollection vectors
        ## these DC variables are matrices of size numofdays x 5 (where 5 is the number of agegroups)
        lm[:, i] = lat[:, agegroup] 
        cm[:, i] = car[:, agegroup]
        sm[:, i] = sym[:, agegroup]
        im[:, i] = inv[:, agegroup]
        rm[:, i] = rec[:, agegroup]
        dn[:, i] = deadn[:, agegroup]
        di[:, i] = deadi[:, agegroup]
      end
      dirname = string("Ag", agegroup)
      if !isdir(dirname) 
        mkdir(dirname)
      end
      info("writing files")
      writedlm(string(dirname, "/latent.dat"),  lm)
      writedlm(string(dirname, "/carriage.dat"), cm)
      writedlm(string(dirname, "/symptomatic.dat"), sm)
      writedlm(string(dirname, "/invasive.dat"), im)
      writedlm(string(dirname, "/recovered.dat"), rm)
      writedlm(string(dirname, "/deadnatural.dat"), dn)
      writedlm(string(dirname, "/deadinvasive.dat"), di)

      ## data files created, running plot script
      println("...data files created, running Rscript")
      run(`Rscript plots.R $dirname`)
    
    end
end

function main(numofsims)
  info("starting simulations with processors: $(nprocs())")
  info("number of simulations set to: $numofsims")
  info("setting up parameters...")
  @everywhere P = HiaParameters(simtime = 30*365, vaccinetime = 10*365, betaone=0.0722, betatwo=0.0526, betathree=0.0426, betafour = 0.0699)
  info("\n $P")
  info("checking if ./serial exists")
  if isdir("./serial") 
    info("...exists") 
  else 
    info("...not found...exiting!")
    throw("./serial does not exist")
  end  
  info("starting main functions...")
  runseed(numofsims, P);
  runpastthirty(numofsims, true, P);
  runpastthirty(numofsims, false, P);  
  #testprocess(50)
  info("simulation scenarios finished!")
end
 
#main(500)
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
 

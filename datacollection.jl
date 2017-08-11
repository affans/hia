type DataCollection  ## data collection type.
    
    ## daily data (broken down by agegroup, aggregated patient)
    lat::Array{Int64}
    car::Array{Int64}
    sym::Array{Int64}
    inv::Array{Int64}       # total invasive
    rec::Array{Int64}
    deadn::Array{Int64}
    deadi::Array{Int64}
    invM::Array{Int64}      # invasive, meningitis
    invP::Array{Int64}      # invasive, pneumonia
    invN::Array{Int64}      # invasive, NPNM

    ## size x 5 matrix.. 5 because we have five "beta" agegroups, and size = simulation time
    DataCollection(size::Integer) = new(zeros(Int64, size, 5),    #lat 
                                    zeros(Int64, size, 5),        #car
                                    zeros(Int64, size, 5),        #sym
                                    zeros(Int64, size, 5),        #inv
                                    zeros(Int64, size, 5),        #rec
                                    zeros(Int64, size, 5),        #deadn
                                    zeros(Int64, size, 5),        #deadi
                                    zeros(Int64, size, 5),        #invM
                                    zeros(Int64, size, 5),        #invP
                                    zeros(Int64, size, 5))        #invN                                    
end



function collectdaily(x, DC::DataCollection, time)
    ## x is human type, but cant declare it yet because include("humans.jl") runs after, so the Human type isnt defined yet.

    ## unpack datacollection vectors  -- these are multidimensional vectors 
    @unpack lat, car, sym, inv, rec, deadn, deadi, invM, invP, invN = DC 
    ## collect our data
    if x.swap == LAT 
        lat[time, x.agegroup_beta] += 1
    elseif x.swap == CAR
        car[time, x.agegroup_beta] += 1
    elseif x.swap == SYMP
        sym[time, x.agegroup_beta] += 1
    elseif x.swap == INV
        inv[time, x.agegroup_beta] += 1
    elseif x.swap == REC
        rec[time, x.agegroup_beta] += 1
    elseif x.swap == DEAD && x.invdeath == false
        deadn[time, x.agegroup_beta] += 1
    elseif x.swap == DEAD && x.invdeath == true
        deadi[time, x.agegroup_beta] += 1
    end  

end


function readjld(prefix, numofsims, key)
  info("starting reading of hdf5/jld files using pmap")
  a = pmap(1:numofsims) do x
    filename = string(prefix, x, ".jld")
    return load(filename)[key]  
  end
  info("pmap finished, returning function. ")
  return a;
end 

function getgroupsizes(humans)
    ag1 = length(find(x -> x.agegroup_beta == 1, humans))
    ag2 = length(find(x -> x.agegroup_beta == 2, humans))
    ag3 = length(find(x -> x.agegroup_beta == 3, humans))
    ag4 = length(find(x -> x.agegroup_beta == 4, humans))
    ag5 = length(find(x -> x.agegroup_beta == 5, humans))    
    return ag1, ag2, ag3, ag4, ag5
end

function processresults(results)
    ## This function accepts an array of DataCollection types - ie, Array{DataCollection}. Each element in this array corresponds to a datacollection object for each simulation. 
    ## Returns: Creates 5 folders for each agegroup, and for each folder, the datafiles for each disease class is created. 
    ## For example, in latent.dat the rows correspond to the number of days in the simulation, and the columns represents the simulations. 
    
    numofsims = length(results)         ## this gives the number of simulations
    numofdays = size(results[1].lat, 1) ## this gives the number of days (pick any matrix from the first simulation to get this.. )

    info("processing results")
    for agegroup = 1:5  ## go through each age group. 
      info("...processing agegroup: $agegroup")
      ## create matrices, for each data collection variable to put the simulation results. 
      ## matrix is numberofdays x numberofsims -- ie, each column represents a simulation
      lm = Matrix{Int64}(numofdays, numofsims)  ## latent matrix
      cm = Matrix{Int64}(numofdays, numofsims)  ## carriage matrix
      sm = Matrix{Int64}(numofdays, numofsims)  ## symptomatic matrix    
      im = Matrix{Int64}(numofdays, numofsims)  ## invasive matrix - total invasive
      rm = Matrix{Int64}(numofdays, numofsims)  ## recovered matrix 
      dn = Matrix{Int64}(numofdays, numofsims)  ## dead natural
      di = Matrix{Int64}(numofdays, numofsims)  ## dead invasive
      mm = Matrix{Int64}(numofdays, numofsims)  ## meningitis invasive
      pn = Matrix{Int64}(numofdays, numofsims)  ## pneumonia invasive
      np = Matrix{Int64}(numofdays, numofsims)  ## NPNM invasive
      
     
      for i = 1:length(results)  # for each simulation
        dc = results[i]  ## get the i'th simulation results. 
        @unpack lat, car, sym, inv, rec, deadn, deadi, invM, invP, invN = dc ## unpack datacollection vectors
        ## these DC variables are matrices of size numofdays x 5 (where 5 is the number of agegroups)
        lm[:, i] = lat[:, agegroup] 
        cm[:, i] = car[:, agegroup]
        sm[:, i] = sym[:, agegroup]
        im[:, i] = inv[:, agegroup]
        rm[:, i] = rec[:, agegroup]
        dn[:, i] = deadn[:, agegroup]
        di[:, i] = deadi[:, agegroup]
        mm[:, i] = invM[:, agegroup]
        pn[:, i] = invP[:, agegroup]
        np[:, i] = invN[:, agegroup]
        
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
      writedlm(string(dirname, "/invasive_men.dat"), mm)
      writedlm(string(dirname, "/invasive_pneu.dat"), pn)
      writedlm(string(dirname, "/invasive_npnm.dat"), np)     
    end

end


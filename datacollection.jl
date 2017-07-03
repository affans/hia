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
    waifu::Array{Int64}


    ## size x 5 matrix.. 5 because we have five "beta" agegroups. 
    DataCollection(size::Integer) = new(zeros(Int64, size, 5), #lat 
                                    zeros(Int64, size, 5),     #car
                                    zeros(Int64, size, 5),     #sym
                                    zeros(Int64, size, 5),     #inv
                                    zeros(Int64, size, 5),     #rec
                                    zeros(Int64, size, 5),     #deadn
                                    zeros(Int64, size, 5),     #deadi
                                    zeros(Int64, size, 5),     #invM
                                    zeros(Int64, size, 5),     #invP
                                    zeros(Int64, size, 5),     #invN
                                    zeros(Int64, 5, 5))      ## waifu, 5x5 matrix (5 agegroups)   
end

function waifumatrix(x, DC::DataCollection, h::Array)
    ### DC.waifu is a 5x5 matrix representing the five beta agegroups
    
    ## if the person had a successful pathogen transfer
    if x.swap == LAT 
        s = x.agegroup_beta
        f = h[x.sickfrom].agegroup_beta
        DC.waifu[s, f] = DC.waifu[s, f]  + 1
    end

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
        ## check for invasive specific-disease. 
        if x.invtype == MENNOD || x.invtype == MENMAJ || x.invtype == MENMIN
            invM[time, x.agegroup_beta] += 1
        elseif x.invtype == PNM
            invP[time, x.agegroup_beta] += 1
        elseif x.invtype == NPNM
            invN[time, x.agegroup_beta] += 1
        end
    elseif x.swap == REC
        rec[time, x.agegroup_beta] += 1
    elseif x.swap == DEAD && x.invdeath == false
        deadn[time, x.agegroup_beta] += 1
    elseif x.swap == DEAD && x.invdeath == true
        deadi[time, x.agegroup_beta] += 1
    end  

end


function processresults(results, foldername)
    ## This function accepts an array of DataCollection types - ie, Array{DataCollection}. Each element in this array corresponds to a datacollection object for each simulation. 
    ## Returns: Creates 5 folders for each agegroup, and for each folder, the datafiles for each disease class is created. 
    ## For example, in latent.dat the rows correspond to the number of days in the simulation, and the columns represents the simulations. 
    
    ## incoming folder name must be "seed" "vaccine" or "pastthirty"
    if foldername != "seed" && foldername != "vaccine" && foldername != "pastthirty"
        throw("foldername must be either: seed, vaccine, pastthirty")
    end
    fn = string(foldername, "_", Dates.monthname(Dates.today()), Dates.day(Dates.today()))
    if !isdir(fn) 
        info("creating results folder: $fn")
    end
    

    numofsims = length(results)         ## this gives the number of simulations
    numofdays = size(results[1].lat, 1) ## this gives the number of days (we pick the latent counter from the first simulation to get this.. )

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

      ## data files created, running plot script
      println("...data files created, running Rscript")
      run(`Rscript plots.R $dirname`)
    
    end

end

function process_waifu(results)
    ## results: should be an array of DC elements. 
    avgwaifu = zeros(Int64, 5, 5)
    for i=1:length(results)
        avgwaifu = avgwaifu + results[i].waifu
    end
    write("WAIFU.dat", avgwaifu)
    return avgwaifu

end

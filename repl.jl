
# if abm

#   data = runmain_parallel(n) ## data contains tuples(Human, DC) returned from main - FOR EACH SIMULATION
# else 
#   include("main.jl")
# end


addprocs(50)
@everywhere include("main.jl")
  


function runmain_parallel(numberofsims, P::HiaParameters)
          
    print("Parameters: \n $P \n")  ## prints to STDOUT - redirect to logfile
    print("starting pmap...\n") 
    
    # cb is the callback function. It updates the progress bar
    totalprogress = numberofsims*(P.simtime + P.vaccinetime)
    results = pmap((cb, x) -> main(x, P, cb), Progress(totalprogress), 1:numberofsims, passcallback=true)   
     ## process all five agegroups
    
    processresults_ag((P.simtime + P.vaccinetime), numberofsims, results)      
    
    return results
end

function runmain()
  numberofsims =1 
  P = HiaParameters(simtime = 50, betaone=0.25, betatwo=0.25, betathree=0.25, betafour = 0.25)       
  print("Parameters: \n $P \n")  ## prints to STDOUT - redirect to logfile
  results = main(1, P, nothing)
end

function processresults_ag(numofdays, numofsims, results)
    ## numofdays - total number of days (ie, pass in P.simtime + P.vaccinetime)
    println("")
    for agegroup = 1:5
      println("...processing agegroup: $agegroup")
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
        dc = results[i][2]   ## get the DC part of the results for each simulation
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

    ## group counts - columns represent group sizes
    grpcnts = zeros(Int64, numofsims, 5)
    for i = 1:length(results)      
      h = results[i][1] 
      grpcnts[i, 1] = length(find(x -> x.agegroup_beta == 1, h))
      grpcnts[i, 2] = length(find(x -> x.agegroup_beta == 2, h))
      grpcnts[i, 3] = length(find(x -> x.agegroup_beta == 3, h))
      grpcnts[i, 4] = length(find(x -> x.agegroup_beta == 4, h))
      grpcnts[i, 5] = length(find(x -> x.agegroup_beta == 5, h))
    end
    writedlm(string("groupcounts.dat"), grpcnts)
end

function runprofile()
    # run to compile
    tic()
    P = HiaParameters(simtime = 1*365, betaone=0.9, betatwo=0.9, betathree=0.9, betafour = 0.9)
    Profile.clear()
    @profile main(1, P, n -> n)
    toc()
    ProfileView.view()        
end

##  --- CHANGE NUMBER OF PROCS --- ###

# @everywhere P = HiaParameters(simtime = 50*365,  betaone=0.0725, betatwo=0.0525, betathree=0.0425, betafour = 0.07)

@everywhere P = HiaParameters(simtime = 30*365, vaccinetime = 10*365, betaone=0.0725, betatwo=0.0526, betathree=0.0425, betafour = 0.0699)
results = runmain_parallel(500, P);

#include("main.jl")
#P = HiaParameters(simtime = 1*365,vaccinetime = 0, betaone=0.9, betatwo=0.9, betathree=0.9, betafour = 0.9)
#main(1, P, n -> 1)
 


  # @unpack lat, car, sym, inv, rec = results[2] ## unpack datacollection vectors
  # P = HiaParameters(simtime = 100, gridsize = 100000)
  # humans = Array{Human}(P.gridsize);
  # initialize(humans, P)
  # demographics(humans, P)
  # a = [statetime(humans[1], P) for i = 1:1000]


  #  @profile for time = 1:P.simtime
  #       for x in humans
  #           # dailycontact(x, P, humans, ag1, ag2, ag3, ag4, n, f, s, t)
  #           # tpp(x, P)
  #           app(x, P)
  #           #update(x, P, DC, time)
  #       end                             
  #   end

# end

  #latavg = zeros(Float64, P.simtime)
    #invavg = zeros(Float64, P.simtime)
    #symavg = zeros(Float64, P.simtime)
    #caravg = zeros(Float64, P.simtime)

    # for i = 1:1
    #     println("running sim $i")
    #     h, dc = main(1, P)
    #     @unpack lat, car, sym, inv, rec = dc ## unpack datacollection vectors
    #     latavg += lat 
    #     invavg += inv
    #     symavg += sym
    #     caravg += car
    # end


    #   a = zeros(Int64, P.gridsize)
    # @time dailycontact(humans, P, a)
    # find(x -> x == 1, a)

    # xx = find(x -> x.age >= 1460 && x.age < 3285, humans)
    # con = zeros(Int64, length(xx))
    # for i = 1:length(xx)
    #     con[i] = a[xx[i]]
    # end
    # find(x -> x==1, con)
    # dailycontact(humans, P)
    # find(x -> x.meetcount == 1, humans)

    # checkdailycontact(h::Array{Human}) = length(find(x -> x.dailycontact > 0, h)) 


  

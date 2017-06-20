
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
    results = pmap((cb, x) -> main(x, P, cb), Progress(numberofsims*P.simtime), 1:numberofsims, passcallback=true)   
     ## process all five agegroups
    println("starting processing of results")
    for a = 1:5 
      processresults_ag(a, P.simtime, numberofsims, results)      
    end
    return results
end

function runmain()
  numberofsims =1 
  P = HiaParameters(simtime = 50, betaone=0.25, betatwo=0.25, betathree=0.25, betafour = 0.25)       
  print("Parameters: \n $P \n")  ## prints to STDOUT - redirect to logfile
  results = main(1, P, nothing)
end

function processresults_ag(agegroup, numofdays, numofsims, results)
    if agegroup < 0 || agegroup > 5 
      error("Hia model => processing results: invalid agegroup")
    end

    println("...processing agegroup: $agegroup")
    ## create 5 matrices, for each data collection variable
    ## matrix is numberofdays x numberofsims -- ie, each column represents a simulation
    lm = Matrix{Int64}(numofdays, numofsims)  
    cm = Matrix{Int64}(numofdays, numofsims)
    sm = Matrix{Int64}(numofdays, numofsims)
    im = Matrix{Int64}(numofdays, numofsims)
    rm = Matrix{Int64}(numofdays, numofsims)    
    dn = Matrix{Int64}(numofdays, numofsims) ## dead natural
    di = Matrix{Int64}(numofdays, numofsims) ## dead invasive
    

    ## group counts - number of rows - 5 for 5 groups
    grpcnts = zeros(Int64, 5, numofsims)

    for i = 1:length(results)  # for each simulation
      dc = results[i][2]                   ## get the DC part of the results for each simulation
      @unpack lat, car, sym, inv, rec, deadn, deadi = dc ## unpack datacollection vectors
      ## these DC variables are matrices of size numofdays x 5 (where 5 is the number of agegroups)

      lm[:, i] = lat[:, agegroup] 
      cm[:, i] = car[:, agegroup]
      sm[:, i] = sym[:, agegroup]
      im[:, i] = inv[:, agegroup]
      rm[:, i] = rec[:, agegroup]
      dn[:, i] = deadn[:, agegroup]
      di[:, i] = deadi[:, agegroup]
      

      h = results[i][1] 
      grpcnts[1, i] = length(find(x -> x.agegroup == 1, h))
      grpcnts[2, i] = length(find(x -> x.agegroup == 2, h))
      grpcnts[3, i] = length(find(x -> x.agegroup == 3, h))
      grpcnts[4, i] = length(find(x -> x.agegroup == 4, h))
      grpcnts[5, i] = length(find(x -> x.agegroup == 5, h))
      
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
    
    writedlm(string("groupcounts.dat"), grpcnts)
end

function runprofile()
    # run to compile
    P = HiaParameters(simtime = 1, gridsize = 100000)
    main(1, P)
    Profile.clear()
    P = HiaParameters(simtime = 365*1, gridsize = 100000)
    @profile h, dc = main(1, P)
    ProfileView.view()            
end

@everywhere P = HiaParameters(simtime = 100*365, betaone=0.065, betatwo=0.045, betathree=0.035, betafour = 0.075)
#@everywhere P = HiaParameters(simtime = 5*365, betaone=0.5, betatwo=0.5, betathree=0.5, betafour = 0.5)
results = runmain_parallel(50, P);

# function scratch()
#  P = HiaParameters(simtime = 100, gridsize = 100000)
#   results = main(1, P, x -> x + 1)
#   DC = DataCollection(P.simtime)





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


  

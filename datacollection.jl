type DataCollection  ## data collection type.
    lat::Array{Int64}
    car::Array{Int64}
    sym::Array{Int64}
    inv::Array{Int64}
    rec::Array{Int64}
    deadn::Array{Int64}
    deadi::Array{Int64}
    invM::Array{Int64}      # invasive, meningitis
    invP::Array{Int64}      # invasive, pneumonia
    invN::Array{Int64}      # invasive, NPNM
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
                                    zeros(Int64, size, 5))     #invN      
end

function collect(x, DC::DataCollection, time)
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
        if x.invtype == MEN
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


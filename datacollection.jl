type DataCollection  ## data collection type.
    lat::Array{Int64}
    car::Array{Int64}
    sym::Array{Int64}
    inv::Array{Int64}
    rec::Array{Int64}
    deadn::Array{Int64}
    deadi::Array{Int64}
    ## size x 5 matrix.. 5 because we have five "beta" agegroups. 
    DataCollection(size::Integer) = new(zeros(Int64, size, 5), zeros(Int64, size, 5), zeros(Int64, size, 5), zeros(Int64, size, 5), zeros(Int64, size, 5), zeros(Int64, size, 5), zeros(Int64, size, 5))
end



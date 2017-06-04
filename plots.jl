using Gadfly

function plot_agedistribution(humans::Array{Human})
    allages = map(x -> x.age, humans)
    find(x -> x == 0, allages)
    plot(x = allages, Geom.histogram)
end
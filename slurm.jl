hosts = @parallel for i=1:64
       println(run(`hostname`))
end
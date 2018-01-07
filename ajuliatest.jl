
a = rand(1)
b = rand(1)

function testcompare(a, b)
    if a < 0.5 && b < 0.5 
        println("Both small")
    else 
        println("Both large")
    end
end

function testcomparetwo(a, b)
    if a < 0.5
        if b < 0.5 
            println("Both small")
        end
    else 
        println("Both large")
    end
end

@code_warntype testcompare(rand(1)[1], rand(1)[1])
@code_warntype testcomparetwo(rand(1)[1], rand(1)[1])

@code_llvm testcompare(rand(1)[1], rand(1)[1])
@code_llvm testcomparetwo(rand(1)[1], rand(1)[1])

@code_lowered testcompare(rand(1)[1], rand(1)[1])

@code_native testcompare(rand(1)[1], rand(1)[1])
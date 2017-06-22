### various distributions
function distribution_age()
    ## gives the cumalative distribution of age 
    ##  julia arrays are 1-based, meaning ProbAge[1] is the 
    ##  probability of being a newborn from 0 - 12 months (ie, <1 years of age)
    ProbAge = Vector{Float64}(100)
    ProbAge[1] = 0.01960239121368
    ProbAge[2] = 0.0442096482691506
    ProbAge[3] = 0.0693730015292646
    ProbAge[4] = 0.0934241623800918
    ProbAge[5] = 0.115807034616989
    ProbAge[6] = 0.139163075212012
    ProbAge[7] = 0.164326428472126
    ProbAge[8] = 0.186848324760184
    ProbAge[9] = 0.209370221048241
    ProbAge[10] = 0.230501876824691
    ProbAge[11] = 0.250799388294175
    ProbAge[12] = 0.269984707354372
    ProbAge[13] = 0.289587098568052
    ProbAge[14] = 0.307382177116641
    ProbAge[15] = 0.325455303767552
    ProbAge[16] = 0.342694286111497
    ProbAge[17] = 0.361601557069373
    ProbAge[18] = 0.377589322952871
    ProbAge[19] = 0.39538440150146
    ProbAge[20] = 0.412623383845405
    ProbAge[21] = 0.429862366189351
    ProbAge[22] = 0.446823300430975
    ProbAge[23] = 0.463784234672598
    ProbAge[24] = 0.48032809676074
    ProbAge[25] = 0.497428055053524
    ProbAge[26] = 0.516891422216043
    ProbAge[27] = 0.53426942861115
    ProbAge[28] = 0.553037675517865
    ProbAge[29] = 0.570693730015293
    ProbAge[30] = 0.586125399694147
    ProbAge[31] = 0.603086333935771
    ProbAge[32] = 0.620464340330877
    ProbAge[33] = 0.63561796190741
    ProbAge[34] = 0.650076463228139
    ProbAge[35] = 0.664395940497706
    ProbAge[36] = 0.678993465869595
    ProbAge[37] = 0.693173919088002
    ProbAge[38] = 0.706381203948283
    ProbAge[39] = 0.719588488808564
    ProbAge[40] = 0.730849436952593
    ProbAge[41] = 0.742805505352426
    ProbAge[42] = 0.753649381342972
    ProbAge[43] = 0.765327401640484
    ProbAge[44] = 0.775615181426387
    ProbAge[45] = 0.787432225775059
    ProbAge[46] = 0.799805366328375
    ProbAge[47] = 0.810927290421243
    ProbAge[48] = 0.822744334769915
    ProbAge[49] = 0.834422355067427
    ProbAge[50] = 0.844988182955651
    ProbAge[51] = 0.855832058946198
    ProbAge[52] = 0.866953983039066
    ProbAge[53] = 0.878353955234256
    ProbAge[54] = 0.887529542610872
    ProbAge[55] = 0.896288057834005
    ProbAge[56] = 0.904768524954817
    ProbAge[57] = 0.913805088280273
    ProbAge[58] = 0.921034338940637
    ProbAge[59] = 0.928680661754483
    ProbAge[60] = 0.935492840261365
    ProbAge[61] = 0.941470874461282
    ProbAge[62] = 0.947170860558877
    ProbAge[63] = 0.952731822605311
    ProbAge[64] = 0.957180592242458
    ProbAge[65] = 0.962324482135409
    ProbAge[66] = 0.966634227721396
    ProbAge[67] = 0.970109829000417
    ProbAge[68] = 0.973585430279438
    ProbAge[69] = 0.97706103155846
    ProbAge[70] = 0.98039760878632
    ProbAge[71] = 0.982621993604894
    ProbAge[72] = 0.984568330321146
    ProbAge[73] = 0.986653691088558
    ProbAge[74] = 0.988321979702489
    ProbAge[75] = 0.989990268316419
    ProbAge[76] = 0.991519532879188
    ProbAge[77] = 0.992492701237314
    ProbAge[78] = 0.993882941748923
    ProbAge[79] = 0.994995134158209
    ProbAge[80] = 0.995690254414014
    ProbAge[81] = 0.99666342277214
    ProbAge[82] = 0.997358543027944
    ProbAge[83] = 0.997636591130265
    ProbAge[84] = 0.998053663283748
    ProbAge[85] = 0.998470735437231
    ProbAge[86] = 0.998748783539552
    ProbAge[87] = 0.998887807590713
    ProbAge[88] = 0.999304879744196
    ProbAge[89] = 0.999443903795357
    ProbAge[90] = 0.999443903795357
    ProbAge[91] = 0.999582927846517
    ProbAge[92] = 0.999582927846517
    ProbAge[93] = 0.999721951897678
    ProbAge[94] = 0.999860975948839
    ProbAge[95] = 0.999860975948839
    ProbAge[96] = 0.999860975948839
    ProbAge[97] = 0.999860975948839
    ProbAge[98] = 0.999860975948839
    ProbAge[99] = 1         
    ProbAge[100] = 1 
    return ProbAge
end

function distribution_ageofdeath(a::Int64, g::GENDER)
    ##matlab curve fitting, 6th/4th degree polynomial...no "center of scale", "bisquare"
    rval = 0.0
    if g == MALE
       p1 =   2.556e-11  #(1.021e-12, 5.01e-11)
       p2 =  -7.062e-09  #-1.438e-08, 2.527e-10)
       p3 =   7.713e-07  #(-6.128e-08, 1.604e-06)
       p4 =  -3.893e-05  #(-8.405e-05, 6.179e-06)
       p5 =   0.0008887  #(-0.0002892, 0.002067)
       p6 =     -0.0073  ##(-0.02043, 0.005831)
       p7 =     0.01888  #(-0.02687, 0.06462)   
       rval =  p1*a^6 + p2*a^5 + p3*a^4 + p4*a^3 + p5*a^2 +  p6*a + p7
    else 
        p1 =    5.19e-08  #(3.968e-08, 6.413e-08)
        p2 =  -5.702e-06  #(-8.142e-06, -3.262e-06)
        p3 =   0.0001986  #(3.823e-05, 0.000359)
        p4 =   -0.002122  #(-0.005999, 0.001755)
        p5 =    0.007877  #(-0.01953, 0.03528) 
        rval = p1*a^4 + p2*a^3 + p3*a^2 + p4*a + p5
    end
    return rval
end

function distribution_contact_transitions()
    con = [2.11 0.15 0.53 0.03
           0.55 0.40 0.50 0.12
           0.56 3.68 3.61 0.13
           0.55 0.55 0.81 1.43]
    # con = [1 0 0 0
    #        0 1 0 0
    #        0 0 1 0
    #        0 0 0 1]

    mat = zeros(Float64, 4, 4)
    cmat = zeros(Float64, 4, 4)
    for i = 1:4
        sumrow = sum(con[i, :])
        for j = 1:4
            mat[i, j] = con[i, j]/sumrow
            cmat[i, j] = sum(mat[i, 1:j])
        end
    end
    
    
#cummat =  [0.7482 0.8014 0.9894 1.0 
#           0.3503 0.6051 0.9236 1.0
#           0.0702 0.5313 0.9837 1.0
#           0.1647 0.3293 0.5719 1.0]
    return mat, cmat
end



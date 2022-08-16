function TOF = fillArea(indexi,indexj,value,TOF)

    for i = indexi
        for j = indexj
            TOF(j,i) = value;
        end
    end
end
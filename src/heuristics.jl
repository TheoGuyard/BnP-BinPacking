function process_root_heuristic()

    if verbose_level>=3 println("\e[93m Processing $root_heuristic at root \e[00m") end

    items = copy(data.S)
    bins = Array{Array{Int},1}()
    capacity = Array{Float32,1}()
    push!(bins,vcat(1,zeros(data.N)))
    push!(capacity,0)
    nb_packed = 0

    while nb_packed < data.N

        i = findmax(items)[2]
        w = items[i]
        items[i] = -Inf
        packed = false

        if root_heuristic == "FFD"
            b = findfirst(c -> (c + w <= data.C), capacity)
        elseif root_heuristic == "WFD"
            available_bins = findall(c -> (c + w <= data.C), capacity)
            if length(available_bins) > 0
                b = available_bins[findmin(capacity[available_bins])[2]]
            else
                b = nothing
            end
        elseif root_heuristic == "BFD"
            available_bins = findall(c -> (c + w <= data.C), capacity)
            if length(available_bins) > 0
                b = available_bins[findmax(capacity[available_bins])[2]]
            else
                b = nothing
            end
        end

        if b != nothing
            if verbose_level>=3 println("\e[34m Item $i with weight $w packed in the bin number $b \e[00m") end
            bins[b][i+1] = 1
            capacity[b] += w
            nb_packed += 1
        else
            if verbose_level>=3 println("\e[36m A new bin is needed \e[00m") end
            push!(bins,vcat(1,zeros(data.N)))
            push!(capacity,w)
            if verbose_level>=3 println("\e[34m Item $i with weight $w packed in bin number $(size(bins,1)) \e[00m") end
            bins[end][i+1] = 1
            nb_packed += 1
        end
    end

    for b in 1:size(bins,1)
        bins[b][1] = 1
    end

    if verbose_level>=3 println("\e[35m $root_heuristic solution with value $(size(bins,1)) found \e[00m") end

    for pattern in 1:size(bins,1)
        push!(column_pool, round.(Int, bins[pattern]))
    end

    global bestsol = bins
    global UB = size(bins,1)

end

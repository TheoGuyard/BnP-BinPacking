function process_root_heuristic()
    """Initial heuristic algorithm before starting the branch-and-price
    exploration. Three heuristics are available : FFD, BFD and WFD. The
    algorithm structure is the same but the choice of the bin is different."""

    if (verbose_level >= 3) println("\e[37mBound initialization with an heuristic \e[00m") end
    if (verbose_level >= 3) println("\e[93m Processing $root_heuristic \e[00m") end

    sizes = copy(data.S)
    bins = Array{Array{Int},1}()
    capacity = Array{Float32,1}()
    push!(bins, vcat(1, zeros(data.N)))
    push!(capacity, 0)
    nb_packed = 0

    while nb_packed < data.N

        # Pack items in decreasing size order
        i = findmax(sizes)[2]
        w = sizes[i]
        sizes[i] = 0
        packed = false

        # Choose the bin according to the heuristic chosen
        if root_heuristic == "FFD"
            # Choose the first bin with enougth space
            b = findfirst(c -> (c + w <= data.C), capacity)
        elseif root_heuristic == "WFD"
            # Choose the bin able to pack the item with the least space left
            available_bins = findall(c -> (c + w <= data.C), capacity)
            if length(available_bins) > 0
                b = available_bins[findmin(capacity[available_bins])[2]]
            else
                b = nothing
            end
        elseif root_heuristic == "BFD"
            # Choose the bin able to pack the item with the more space left
            available_bins = findall(c -> (c + w <= data.C), capacity)
            if length(available_bins) > 0
                b = available_bins[findmax(capacity[available_bins])[2]]
            else
                b = nothing
            end
        end

        # A bin is found to pack the item
        if b != nothing
            if (verbose_level >= 3) println("\e[34m Item $i with weight $w packed in the bin number $b \e[00m") end
            bins[b][i+1] = 1
            capacity[b] += w
            nb_packed += 1
        # A new bin is needed to pack the item
        else
            if (verbose_level >= 3) println("\e[36m A new bin is needed \e[00m") end
            push!(bins, vcat(1, zeros(data.N)))
            push!(capacity, w)
            if (verbose_level >= 3) println("\e[34m Item $i with weight $w packed in bin number $(size(bins,1)) \e[00m") end
            bins[end][i+1] = 1
            nb_packed += 1
        end
    end

    if (verbose_level >= 3) println("\e[35m $root_heuristic solution with value $(size(bins,1)) found \e[00m") end

    global bestsol = bins
    global UB = size(bins, 1)
    global rootHeuristicObjective = UB

end

function read_data(instance::AbstractString)

    # Datasets are under .BPP format :
    # - First line : number of items
    # - Second line : bin capacity
    # - Lines 3 to N+2 : item size
    # The upper-bound on the number of bins is equal to the number of items

    data = Data()
    file = readdlm(string(dirname(@__FILE__), "/../", instance), '\n')

    if verbose_level >= 1 println("\e[92m******** Read instance file **********\e[00m") end

    data.ID = split(instance, "/")[end]
    data.N = file[1]
    data.C = file[2]
    data.S = file[3:(data.N+2)]
    data.B = data.N

    if verbose_level >= 1

    println("Instance : $(data.ID)")
    println("Bin capacity : $(data.C)")
    println("Number of items : $(data.N)")

    println("\e[92m************* Settings ***************\e[00m")
    println("Branching rule : $branching_rule")
    println("Subproblem method : $subproblem_method")
    println("Rooth heuristic : $root_heuristic")
    println("Tree heuristic: $tree_heuristic")
    println("Queueing method : $queueing_method")
    println("Verbose level : $verbose_level")

    end

    return data
end

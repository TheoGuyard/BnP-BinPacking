include("typedef.jl")
include("node_ryan_foster.jl")
include("node_generic.jl")
include("display.jl")
include("heuristics.jl")

function solve_BnP()

    if !check_settings()
        return nothing
    end

    println("\e[92m*********** Solve BnP ****************\e[00m")

    if verbose_level<=1 println("\e[37mTree is beeing explored ... \e[00m") end

    global column_pool = Array{Array{Int,1},1}()
    push!(column_pool, vcat(data.N,ones(Int,data.N)))

    global UB = Inf
    global LB = -Inf
    global bestsol

    global tree = Vector{Node}()
    global queue = Vector{Int}()

    push!(tree, Node(0,[],-Inf,[],[]))
    push!(queue, 1)

    if verbose_level>=3 println("\e[37mRoot \e[00m") end
    if root_heuristic != "None"
        process_root_heuristic()
    end
    if verbose_level>=2 println("\e[37mBounds : LB=$LB, UB=$UB\e[00m") end

    while length(queue) > 0

        if verbose_level>=3 println("\e[37mQueue : $queue\e[00m") end
        current = queue[end]

        if branching_rule == "ryan_foster"
            nodesol = process_node_ryan_foster(current)
        elseif branching_rule == "generic"
            nodesol = process_node_generic(current)
        end

        if (size(nodesol,1)!=0) && (tree[current].lb<=UB)
            (item1,item2) = calculate_branching(nodesol)
            if (item1,item2) != (0,0)
                push_to_queue(current, item1, item2)
            else
                if verbose_level>=3 println("\e[37mInterger solution with value $(tree[current].lb) found\e[00m") end
            end
        elseif (tree[current].lb>UB)
            if verbose_level>=3 println("\e[37mThe node is pruned by bound\e[00m") end
        else
            if verbose_level>=3 println("\e[37mThe node is infeasible\e[00m") end
        end

        global LB = tree[current].lb
        for i in queue
            if tree[i].lb <= LB global LB = tree[i].lb end
        end
        if verbose_level>=2 println("\e[37mBounds : LB=$LB, UB=$UB\e[00m") end

        # Delete the current, prunes and infeasible nodes
        deleteat!(queue,findfirst(x -> x == current, queue))
        deleteat!(queue, unique(nodestobedeleted))

        if (2*(UB-LB)/(UB+LB))<=ϵ
            break
        end
    end
    display_bnp_result(bestsol)
end

function calculate_branching(node_sol)
    # Select a pair of items for which the sum of the amount of patterns
    # containing i and j is fractionnal
    item1 = 0
    item2 = 0
    found = false
    for i in 1:data.N
        for j in 1:data.N
            if j!=i
                w = [node_sol[p][1] for p in 1:size(node_sol,1) if node_sol[p][i+1]==1 && node_sol[p][j+1]==1]
                if w != []
                    w = sum(w)
                    if maximum(w - floor.(w)) >= ϵ
                        item1 = i
                        item2 = j
                        found = true
                        break
                    end
                end
            end
        end
        found && break
    end
    return (item1,item2)
end

function push_to_queue(nodeindex, item1, item2)
    if verbose_level>=3 println("\e[35m Branching on items $item1 and $item2\e[00m") end
    # Up branch
    push!(tree,
        Node(nodeindex,
            [],
            tree[nodeindex].lb,
            vcat((item1,item2), tree[nodeindex].upbranch),
            tree[nodeindex].downbranch))
    push!(tree[nodeindex].children, length(tree))
    if queueing_method == "LIFO"
        push!(queue, length(tree))
    else
        pushfirst!(queue, length(tree))
    end
    # Down branch
    push!(tree,
        Node(nodeindex,
            [],
            tree[nodeindex].lb,
            tree[nodeindex].upbranch,
            vcat((item1,item2), tree[nodeindex].downbranch)))
    push!(tree[nodeindex].children, length(tree))
    if queueing_method == "FIFO"
        push!(queue, length(tree))
    else
        pushfirst!(queue, length(tree))
    end
end


function check_settings()

    errors = []

    if !(branching_rule in ["ryan_foster", "generic"])
        push!(errors,"< branching_rule > parameter should either be 'ryan_foster' or 'generic'")
    end

    if !(subproblem_method in ["gurobi", "dynamic"])
        push!(errors,"< subproblem_method > parameter should either be 'gurobi' or 'dynamic'")
    end

    if !(root_heuristic in ["FFD", "BFD", "WFD", "None"])
        push!(errors,"< root_heuristic > parameter should either be 'FFD', 'BFD' 'WFD', or 'None")
    end

    if !(tree_heuristic in [true, false])
        push!(errors,"< tree_heuristic > parameter should either be true or fasle")
    end

    if !(queueing_method in ["FIFO", "LIFO"])
        push!(errors,"< queueing_method > parameter should either be 'FIFO' or 'LIFO'")
    end

    if !(verbose_level in [1,2,3])
        push!(errors,"< verbose_level > parameter should either be 1, 2 or 3")
    end

    if !((ϵ > 10^(-16)) && (ϵ < 10^(-4)))
        push!(errors,"< ϵ > parameter should be between 10^(-16) and 10^(-4)")
    end

    if length(errors)>0
        println("\e[91m*************** Error ****************\e[00m")
        for error in errors
            println(error)
        end
        println("More informations about the parameters in the README.md file.")
        return false
    end
    return true

end

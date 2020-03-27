include("typedef.jl")
include("ryan_foster/node.jl")
include("display.jl")

function solve_BnP()

    if !check_settings()
        return []
    end

    println("\e[92m*********** Solve BnP ****************\e[00m")

    # Each column corresponds to a pattern with the cost in 1st index
    global column_pool = Array{Array{Int,1},1}()
    # Artificial pattern with a high cost and with all the items in it
    push!(column_pool, vcat(data.N,ones(Int,data.N)))
    # Artificial empty pattern with a 0 cost and no itemps in it
    # push!(column_pool, zeros(Int,data.N+1))

    global UB = Inf
    global LB = -Inf

    # The tree is a list of nodes
    global tree = Vector{Node}()
    # Nodes to be processed are stored in a queue by their index in the tree vector
    global queue = Vector{Int}()

    # Root of the tree
    push!(tree, Node(0,[],-Inf,[],[]))
    push!(queue, 1)

    global bestsol

    # Process nodes while the tree isn't fully explored
    while length(queue) > 0

        println("Queue : $queue")
        current = queue[end]

        # Patterns selected for the current node
        nodesol = process_node_ryan_foster(current)

        if (size(nodesol,1)!=0) && (tree[current].lb<=UB)
            (item1,item2) = calculate_branching(nodesol)
            if (item1,item2)!=(0,0)
                println("\e[35m Two new nodes are created branching on items $item1 and $item2\e[00m")
                # Up branch
                push!(tree,
                    Node(current,
                        [],
                        tree[current].lb,
                        vcat((item1,item2), tree[current].upbranch),
                        tree[current].downbranch))
                push!(tree[current].children, length(tree))
                if queueing_method == "LIFO"
                    push!(queue, length(tree))
                else
                    pushfirst!(queue, length(tree))
                end
                # Down branch
                push!(tree,
                    Node(current,
                        [],
                        tree[current].lb,
                        tree[current].upbranch,
                        vcat((item1,item2), tree[current].downbranch)))
                push!(tree[current].children, length(tree))
                if queueing_method == "LIFO"
                    push!(queue, length(tree))
                else
                    pushfirst!(queue, length(tree))
                end
            else
                println("\e[37mInterger solution with value $(tree[current].lb) found\e[00m")
            end
        elseif size(nodesol,1)==0
            println("\e[37mThe node is infeasible\e[00m")
        else
            println("\e[37mThe node is pruned by bound\e[00m")
        end

        global LB = tree[current].lb
        for i in queue
            if tree[i].lb <= LB global LB = tree[i].lb end
        end
        println("\e[37mLB=$LB, UB=$UB\e[00m")

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

function check_settings()

    errors = []

    if !(branching_rule in ["ryan_foster", "generic"])
        push!(errors,"< branching_rule > parameter should either be 'ryan_foster' or 'generic'")
    end

    if !(subproblem_method in ["gurobi", "dynamic"])
        push!(errors,"< subproblem_method > parameter should either be 'gurobi' or 'dynamic'")
    end

    if !(root_heuristic in [true, false])
        push!(errors,"< root_heuristic > parameter should either be true or fasle")
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

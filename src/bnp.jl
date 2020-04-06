include("typedef.jl")
include("node.jl")
include("display.jl")
include("heuristics.jl")

function solve_BnP(maxTime=Inf, benchmark=false)
    """Core structure of the branch-and-price algorithm."""

    start = Dates.second(Dates.now())

    if !check_settings()
        return nothing
    end

    if (verbose_level >= 1) println("\e[92m*********** Solve BnP ****************\e[00m") end

    if (verbose_level == 1) println("\e[37mTree is beeing explored ... \e[00m") end

    # Each column correspond to a pattern. The first element is the column cost and the other
    # elements indicate if an item is used in the pattern or not.
    global column_pool = Array{Array{Int,1},1}()
    push!(column_pool, vcat(data.B, ones(Int, data.N)))

    global UB = Inf
    global LB = -Inf
    global bestsol = []
    global nbNodeExplored = 0

    # Nodes are stored in a tree and then stored in the queue using their tree index
    global tree = Vector{Node}()
    global queue = Vector{Int}()

    # Root initialization
    push!(tree, Node())
    push!(queue, 1)

    # Root heuristic can be run before the branch-and-price
    if (root_heuristic != "None")
        if (verbose_level >= 3) println("\e[37mRoot \e[00m") end
        process_root_heuristic()
        if (verbose_level >= 2) println("\e[37mBounds : LB=$LB, UB=$UB\e[00m") end
    end
    global rootHeuristicObjective = UB

    while length(queue) > 0

        if (Dates.second(Dates.now())-start)/1000 > maxTime
            println("\e[91mMax time reached !\e[00m")
            break
        end

        if (verbose_level >= 3) println("\e[37mQueue : $queue\e[00m") end

        current = queue[end]
        # Process the node until optimality is reached
        nodesol = process_node(current)
        # Wether continue the branching or prune the current node
        branch_or_prune(current, nodesol)
        # Update global bounds
        update_bounds()
        # Test if other nodes can be pruned regarding to the new bounds
        prune_tree(current)

        if (2 * (UB - LB) / (UB + LB)) <= ϵ
            break
        end
    end

    stop = Dates.second(Dates.now())
    runningTime = min((stop-start)/1000, maxTime)
    if benchmark
        return UB, rootHeuristicObjective, nbNodeExplored, runningTime
    else
        display_bnp_result(bestsol, runningTime)
        return nothing
    end

end


function prune_tree(nodeindex)
    """Remove the current node from the queue and prune nodes that can be deleted besides it."""

    deleteat!(queue, findfirst(x -> x == nodeindex, queue))
    deleteat!(queue, unique(nodestobedeleted))

end


function branch_or_prune(nodeindex, nodesol)
    """Decide how to continue the algorithm after the current node processing."""

    # First case, a new branch is possible
    if (size(nodesol, 1) != 0) && (tree[nodeindex].lb <= UB)
        (item1, item2) = calculate_branching(nodesol)
        # First subcase, items to branch on are found so new nodes are created
        if (item1, item2) != (0, 0)
            create_child_nodes(nodeindex, item1, item2)
        # Second subcase, integer solution is found so branch exploration is ended
        else
            if (verbose_level >= 3) println("\e[37mInterger solution with value $(tree[nodeindex].lb) found\e[00m") end
        end
    # Second case, the node is pruned by bound
    elseif (tree[nodeindex].lb > UB)
        if (verbose_level >= 3) println("\e[37mThe node is pruned by bound\e[00m") end
    # Third case, the node is pruned by infeasibility
    else
        if (verbose_level >= 3) println("\e[37mThe node is infeasible\e[00m") end
    end

end


function update_bounds()
    """Update global bounds regarding to the new solution provided by the node."""

    global LB = minimum([tree[i].lb for i in queue])
    if (verbose_level >= 2) println("\e[37mBounds : LB=$LB, UB=$UB\e[00m") end

end


function calculate_branching(nodesol)
    """Find two items to branch on."""

    for i = 1:data.N
        for j = 1:data.N
            if j != i
                # Gather amount of usage of column containing both item i and j
                costs = [nodesol[p][1] for p in 1:size(nodesol, 1) if (nodesol[p][i+1]==1 && nodesol[p][j+1]==1)]
                if costs != []
                    sum_costs = sum(costs)
                    # Check wether the sum of the amount of usage is fractionnal or not
                    if maximum(sum_costs - floor.(sum_costs)) >= ϵ
                        return (i, j)
                    end
                end
            end
        end
    end

    # No items to branch on
    return (0, 0)

end


function create_child_nodes(nodeindex, item1, item2)
    """Push two new nodes after a branching is found."""

    if (verbose_level >= 3) println("\e[35m Branching on items $item1 and $item2\e[00m") end

    # New node with up-branching rules
    push!(tree,
        Node(
            nodeindex,          #  Index of the parent node
            [],                 # Index of the child nodes
            tree[nodeindex].lb,         # Lower bound initialized as the value of parent lower bound
            vcat((item1, item2), tree[nodeindex].upBranch),     # New up-branching rules
            tree[nodeindex].downBranch,     # Down-branching rules of the parent node
            calculate_subproblem_sets(nodeindex, item1, item2, "up")   # New ubproblem rules (only used for the generic branching scheme)
        )
    )
    add_child(nodeindex)

    # New node with down-branching rules
    push!(
        tree,
        Node(
            nodeindex,          #  Index of the parent node
            [],                 # Index of the child nodes
            tree[nodeindex].lb,     # Lower bound initialized as the value of parent lower bound
            tree[nodeindex].upBranch,   # Up-branching rules of the parent node
            vcat((item1, item2), tree[nodeindex].downBranch),   # New down-branching rules
            calculate_subproblem_sets(nodeindex, item1, item2, "down")   # New ubproblem rules (only used for the generic branching scheme)
        ),
    )
    add_child(nodeindex)

end

function calculate_subproblem_sets(nodeindex, item1, item2, branch)
    """Compute the new branching schemes for the generic branching rules."""

    # Each existing branching scheme is splitted into two new branching schemes where the new rules are added
    subproblemSets = []

    if branching_rule == "ryan_foster"
        return copy(tree[nodeindex].subproblemSets)
    end

    for s in tree[nodeindex].subproblemSets
        if s.coeff > 1
            # Set splits into two different sets   
            r = s.rules[1]
            # First set (with coefficient L-1)
            if branch == "up"
                newRule1 = Rule(unique(vcat(r.setzero, [item1, item2])), r.setone)
            elseif branch == "down"
                newRule1 = Rule(unique(vcat(r.setzero, [item1])), r.setone)
            end
            # Second set (with coeficient 1)
            if branch == "up"
                newRule2 = Rule(r.setzero, unique(vcat(r.setone, [item1, item2])))
            elseif branch == "down"
                newRule2 = Rule(unique(vcat(r.setzero, [item2])), unique(vcat(r.setone, [item1])))
            end
            # Add the new subproblem sets
            if size(intersect(newRule2.setzero, newRule2.setone),1) == 0
                push!(subproblemSets, SubproblemSet([newRule1], s.coeff-1))
                push!(subproblemSets, SubproblemSet([newRule2], 1))
            else
                push!(subproblemSets, SubproblemSet([newRule1], s.coeff))
            end
        else
            # New rules are added to the set but the coefficient remains the same
            coeff =  s.coeff
            rules = []
            for r in s.rules
                if branch == "up"
                    newRule1 = Rule(unique(vcat(r.setzero, [item1, item2])), r.setone)
                    newRule2 = Rule(r.setzero, unique(vcat(r.setone, [item1, item2])))
                elseif branch == "down"
                    newRule1 = Rule(unique(vcat(r.setzero, item1)), r.setone)
                    newRule2 = Rule(unique(vcat(r.setzero, item2)), unique(vcat(r.setone, item1)))
                end
                if size(intersect(newRule1.setzero, newRule1.setone),1) == 0
                    push!(rules, newRule1)
                end
                if size(intersect(newRule2.setzero, newRule2.setone),1) == 0
                    push!(rules, newRule2)
                end
            end
            push!(subproblemSets, SubproblemSet(rules, coeff))
        end
    end

    return subproblemSets

end

function add_child(nodeindex)
    """Add a new node to the queue according to the queuing method."""

    push!(tree[nodeindex].children, length(tree))

    if queueing_method == "LIFO"
        push!(queue, length(tree))
    elseif queueing_method == "FIFO"
        pushfirst!(queue, length(tree))
    end

end


function check_settings()

    errors = []

    if !(typeof(data.C) in [Int8, Int16, Int32, Int64, Int128])
        push!(errors, "Capacity has non-integer type")
    end

    if !(typeof(data.N) in [Int8, Int16, Int32, Int64, Int128])
        push!(errors, "Number of items has non-integer type")
    end

    if any(s -> !(typeof(s) in [Int8, Int16, Int32, Int64, Int128]), data.S)
        push!(errors, "At least one of the items has non-integer type")
    end

    if any(s -> (s > data.C), data.S)
        push!(errors, "At least one of the items is larger than the bin capacity")
    end

    if !(branching_rule in ["ryan_foster", "generic"])
        push!(errors, "< branching_rule > parameter should either be 'ryan_foster' or 'generic'")
    end

    if !(subproblem_method in ["gurobi", "dynamic"])
        push!(errors, "< subproblem_method > parameter should either be 'gurobi' or 'dynamic'")
    end

    if !(root_heuristic in ["FFD", "BFD", "WFD", "None"])
        push!(errors, "< root_heuristic > parameter should either be 'FFD', 'BFD' 'WFD', or 'None")
    end

    if !(tree_heuristic in [true, false])
        push!(errors, "< tree_heuristic > parameter should either be true or fasle")
    end

    if !(queueing_method in ["FIFO", "LIFO"])
        push!(errors, "< queueing_method > parameter should either be 'FIFO' or 'LIFO'")
    end

    if !(verbose_level in [0, 1, 2, 3])
        push!(errors, "< verbose_level > parameter should either be 1, 2 or 3 and can be 0 only for benchmarks")
    end

    if !((ϵ > 10^(-16)) && (ϵ < 10^(-4)))
        push!(errors, "< ϵ > parameter should be between 10^(-16) and 10^(-4)")
    end

    if length(errors) > 0
        println("\e[91m*************** Error ****************\e[00m")
        for error in errors
            println(error)
        end
        println("More informations about the parameters in the README.md file.")
        return false
    end

    return true
end

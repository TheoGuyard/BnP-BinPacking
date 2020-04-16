using Printf
include("typedef.jl")
include("node.jl")
include("display.jl")
include("root_heuristics.jl")
include("tree_heuristics.jl")

function solve_BnP(maxTime=Inf, benchmark=false)
    """Core structure of the branch-and-price algorithm."""

    # If settings are incorrect, the algorithm won't start
    if !check_settings()
        return nothing
    end

    if (verbose_level >= 1) println("\e[92m*********** Solve BnP ****************\e[00m") end
    if (verbose_level == 1) println("\e[37mTree is beeing explored ... \e[00m") end

    start = Dates.second(Dates.now())

    # Each column correspond to a pattern. The first element is the column cost and the other
    # elements indicate if an item is used in the pattern or not.
    global column_pool = Array{Array{Int,1},1}()
    # An artificial column with a high cost is added to make every master
    # problem at least feasible with this column.
    push!(column_pool, vcat(data.B, ones(Int, data.N)))

    global UB = data.B
    global LB = ceil(sum(data.S)/data.C)
    global bestsol = []
    global rootHeuristicObjective = UB
    global nbNodeExplored = 0

    # Nodes are stored in a tree and stored in the queue using their tree index
    global tree = Vector{Node}()
    global queue = Vector{Int}()

    # An heuristic can be run before the branch-and-price to obtain a first UB
    if (root_heuristic != "None")
        process_root_heuristic()
        if (verbose_level >= 2) println("\e[37mBounds : LB=$LB, UB=$UB | GAP : $(get_gap()) % | Nodes explored : 0\e[00m") end
    end

    # Tree initialization with the root
    push!(tree, Node())
    push!(queue, 1)

    # Explore the tree while the are nodes to be explored
    while length(queue) > 0

        # Stop the algorithm is the <maxTime> is reached
        if (Dates.second(Dates.now())-start)/1000 > maxTime
            println("\e[91mMax time reached !\e[00m")
            break
        end

        if (verbose_level >= 3) println("\e[37mQueue : $queue\e[00m") end

        # Pop the last node in the queue and solve it to optimality
        current = queue[end]
        nodesol = process_node(current)

        # Continue the exploration of the branch or prune the current node
        branch_or_prune(current, nodesol)

        # Update global LB and UB
        update_bounds()

        # Test if other nodes can be pruned regarding to the new bounds
        prune_tree(current)

        # Stop the BnP when LB ~ UB
        if (2 * (UB - LB) / (UB + LB)) <= ϵ
            break
        end
    end

    stop = Dates.second(Dates.now())
    runningTime = min((stop-start)/1000, maxTime)

    # If the BnP is run for a benchmark, the resuts are returned but in a
    # standard case, they are printed to the console
    if benchmark
        return UB, rootHeuristicObjective, nbNodeExplored, runningTime
    else
        display_bnp_result(bestsol, runningTime)
        return nothing
    end

end

function get_gap()
    gap = 100 * (UB - LB) / UB
    return round(gap, digits=2)
end

function prune_tree(nodeindex)
    """Remove the current node from the queue and prune nodes that can be
    deleted beside it."""

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
            # Improve the UB with an heuristic
            process_tree_heuristic(nodesol)
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
    """Update global bounds regarding to the new solution provided by the
    last node."""

    global LB = minimum([tree[i].lb for i in queue])
    if (verbose_level > 2) println("\e[37mBounds : LB=$LB, UB=$UB | GAP : $(get_gap()) % | Nodes explored : $nbNodeExplored \e[00m") end
    if (verbose_level == 2)
        if nbNodeExplored % 10 == 0
            println("\e[37mBounds : LB=$LB, UB=$UB | GAP : $(get_gap()) % | Nodes explored : $nbNodeExplored \e[00m")
        end
    end
end


function calculate_branching(nodesol)
    """Find two items for the branching."""

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
    """Push two new nodes in the queue with new branching constraints."""

    if (verbose_level >= 3) println("\e[35m Branching on items $item1 and $item2\e[00m") end

    # New node with up-branching rules
    push!(tree,
        Node(
            nodeindex,  #  Index of the parent node
            [], # Index of the child nodes
            tree[nodeindex].lb, # Lower bound initialized as the value of parent lower bound
            vcat((item1, item2), tree[nodeindex].upBranch), # New up-branching rules
            tree[nodeindex].downBranch, # Down-branching rules of the parent node
            calculate_subproblem_sets(nodeindex, item1, item2, "up")    # New subproblem rules (only used for the generic branching scheme)
        )
    )
    add_child(nodeindex)

    # New node with down-branching rules
    push!(
        tree,
        Node(
            nodeindex,  # Index of the parent node
            [], # Index of the child nodes
            tree[nodeindex].lb, # Lower bound initialized as the value of parent lower bound
            tree[nodeindex].upBranch,   # Up-branching rules of the parent node
            vcat((item1, item2), tree[nodeindex].downBranch),   # New down-branching rules
            calculate_subproblem_sets(nodeindex, item1, item2, "down")   # New subproblem rules (only used for the generic branching scheme)
        ),
    )
    add_child(nodeindex)

end

function calculate_subproblem_sets(nodeindex, item1, item2, branch)
    """Compute the new branching schemes for the generic branching rule."""

    # Each existing branching scheme is splitted into two new branching schemes
    # where the new rules are added
    subproblemSets = []

    # For the Ryan & Foster branching rule, the <subproblemSets> are not used
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
            # Add the new subproblem sets if they are not incompatible
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
    """Add a new node to the queue and the tree according to the
    queuing method."""

    push!(tree[nodeindex].children, length(tree))

    if queueing_method == "LIFO"
        push!(queue, length(tree))
    elseif queueing_method == "FIFO"
        pushfirst!(queue, length(tree))
    elseif queueing_method == "Hybrid"
        if UB == data.B
            push!(queue, length(tree))
        else
            pushfirst!(queue, length(tree))
        end
    end

end


function check_settings()
    """Check the settings passed for the BnP algorithm."""

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

    if !(tree_heuristic in ["MIRUP", "BRUSIM", "BRURED", "BOPT", "BRUSUC", "CSTAOPT", "None"])
        push!(errors, "< tree_heuristic > parameter should either be 'MIRUP', 'BRUSIM',
        'BRURED', 'BOPT' 'BRUSUC' 'CSTAOPT' or 'None'")
    end

    if !(queueing_method in ["FIFO", "LIFO", "Hybrid"])
        push!(errors, "< queueing_method > parameter should either be 'FIFO', 'LIFO' or 'Hybrid'")
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

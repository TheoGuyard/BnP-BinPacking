include("typedef.jl")
include("node.jl")
include("display.jl")

function solve_BnP()

    println("\e[95m********** Solve BnP ****************\e[00m")

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
        nodesol = process_node(current)

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
                push!(queue, length(tree))
                # Down branch
                push!(tree,
                    Node(current,
                        [],
                        tree[current].lb,
                        tree[current].upbranch,
                        vcat((item1,item2), tree[current].downbranch)))
                push!(tree[current].children, length(tree))
                push!(queue, length(tree))
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

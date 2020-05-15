include("master.jl")
include("subproblem.jl")


function process_node(nodeindex)
    """Process a tree node."""

    if verbose_level >= 3
        println("\e[93m Processing node $nodeindex \e[00m")
        println("\e[96m Up-branch pairs are : $(tree[nodeindex].upBranch)")
        println(" Down-branch pairs are : $(tree[nodeindex].downBranch)")
        println(" Number of subproblem sets : $(size(tree[nodeindex].subproblemSets,1)) \e[00m")
    end

    global nodestobedeleted = []
    global nbNodeExplored += 1

    # Keep only the columns satisfying the current branching rules
    if branching_rule == "generic"
        node_pool = calculate_columns_generic(nodeindex)
    elseif branching_rule == "ryan_foster"
        node_pool = calculate_columns_ryan_foster(nodeindex)
    end

    # Initialize the master problem
    master, alpha, packed, redundant = solve_master(node_pool, tree[nodeindex].subproblemSets)

    while true

        # Gather master outputs
        π = JuMP.dual.(packed)
        σ = JuMP.dual.(redundant)
        value = JuMP.objective_value(master)
        solution = JuMP.value.(alpha)

        # Check if the solution is integer
        if maximum(solution - round.(solution)) <= ϵ
            if (verbose_level >= 3) println("\e[35m Feasible solution with value $value found \e[00m") end
            if value <= UB
                global UB = value
                global bestsol = calculate_solution(solution, node_pool)
            end
            # Delete nodes with too high lower bound
            for i = 1:length(queue)-1
                if tree[queue[i]].lb >= UB
                    push!(nodestobedeleted, i)
                end
            end
        end

        nodeub = value
        nodelb = sum(π)
        min_reduced_cost = 0

        # Solve one subproblem per branching rules inside a subproblem Set.
        # For the Ryan & Foster rules, there is only one subproblem with one
        # rule so only one subproblem is solved.
        for s in 1:size(tree[nodeindex].subproblemSets,1)
            node_infeasible = true
            for r in tree[nodeindex].subproblemSets[s].rules
                # Solve the subproblem and compute the real reduced cost
                subproblem_obj, column = solve_subproblem(nodeindex, r, π)
                reduced_cost = subproblem_obj - σ[s]
                # Check is subproblem is feasible
                if subproblem_obj < Inf
                    node_infeasible = false
                    # Update minimum reduced cost
                    if reduced_cost <= min_reduced_cost
                        min_reduced_cost = reduced_cost
                    end
                    pattern = findall(x -> x != 0, column)
                    # Check if the solution needs to be added to the restricted master problem
                    if reduced_cost < -ϵ
                        # The cost of a new column is always 1
                        push!(column_pool, vcat(1, round.(column)))
                        push!(node_pool, vcat(1, round.(column)))
                        # Add the new pattern to the master problem
                        push!(alpha, @variable(master, lower_bound = 0))
                        set_name(alpha[end], "alpha_$(size(column_pool,1))")
                        for i = 1:data.N
                            set_normalized_coefficient(packed[i], alpha[end], column[i])
                        end
                        set_objective_function(master, objective_function(master) + alpha[end])
                        if (verbose_level >= 3) println("\e[34m Pattern with items $pattern added \e[00m") end
                    end
                    nodelb += subproblem_obj
                    if node_infeasible
                        # Node infeasible if none of the patterns of a subset
                        # can be made.
                        return []
                    end
                end
            end
        end

        # Update bound
        tree[nodeindex].lb = nodelb

        # If no subproblems are added and node is not degenerated, the node
        # processing is stopped
        if (2 * abs((nodeub - tree[nodeindex].lb)) / abs((nodeub + tree[nodeindex].lb)) < ϵ) || (min_reduced_cost >= -ϵ)
            if solution[1] >= ϵ
                if (verbose_level >= 3) println("\e[36m Artificial column used, node is infeasible \e[00m") end
                return []
            end
            if verbose_level >= 3
                println("\e[36m Node relaxation is solved to optimality")
                println(" Node upper bound is $nodeub, Node lower bound is $(tree[nodeindex].lb) \e[00m")
            end
            return calculate_solution(solution, node_pool)
        end
        optimize!(master)
    end
end

function calculate_solution(mastersol, node_pool)
    """Outputs the solution in a proper format."""

    # Pattern selected is the master solution with coefficient in first index
    x = Array{Array{Float32},1}()
    for c in 1:size(mastersol,1)
        if mastersol[c] >= ϵ push!(x, vcat(mastersol[c],node_pool[c][2:data.N+1])) end
    end
    return x
end


function calculate_columns_generic(nodeindex)
    """Calculate columns satisfying current branching rules for the
    generic branching method."""

    # Artificial column is always added to the node pool
    node_pool = Array{Array{Int,1},1}()
    push!(node_pool, column_pool[1])

    for c = 2:size(column_pool, 1)
        add = true
        for s in tree[nodeindex].subproblemSets
            for r in s.rules
                for i in r.setzero
                    if column_pool[c][i+1] != 0
                        add = false
                        break
                    end
                end
                if add
                    for i in r.setone
                        if column_pool[c][i+1] != 1
                            add = false
                            break
                        end
                    end
                end
            end
            if add
                push!(node_pool, column_pool[c])
            end
        end
    end

    return node_pool

end


function calculate_columns_ryan_foster(nodeindex)
    """Calculate columns satisfying current branching rules for the
    Ryan and Foster branching method."""

    # Keep only columns satisfying current branching constraints
    node_pool = Array{Array{Int,1},1}()
    # Artificial pattern
    push!(node_pool, column_pool[1])
    for c = 2:size(column_pool, 1)
        add = true
        for (i, j) in tree[nodeindex].upBranch
            if column_pool[c][i+1] != column_pool[c][j+1]
                add = false
                break
            end
        end
        if add
            for (i, j) in tree[nodeindex].downBranch
                if column_pool[c][i+1] + column_pool[c][j+1] > 1
                    add = false
                    break
                end
            end
        end
        if add
            push!(node_pool, column_pool[c])
        end
    end
    return node_pool
end

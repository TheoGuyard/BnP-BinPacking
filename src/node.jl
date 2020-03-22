include("master.jl")
include("slave.jl")

function process_node(nodeindex)

    println("\e[93m Processing node $nodeindex \e[00m")
    println("\e[96m Up-branch pairs are : $(tree[nodeindex].upbranch)")
    println(" Down-branch pairs are : $(tree[nodeindex].downbranch) \e[00m")

    # Nodes to be deleted after the node treatment
    global nodestobedeleted = []
    # Use only the columns verifying the current branching rules
    node_pool = calculate_columns(nodeindex)

    packed, alpha, master = solve_master(node_pool)

    while true

        node_infeasible = false

        # Recover master result
        π = JuMP.dual.(packed)
        value = JuMP.objective_value(master)
        solution = JuMP.value.(alpha)

        if maximum(solution - floor.(solution)) <= ϵ
            # Solution is feasible, upper-bound and best node are updated
            println("\e[32m Feasible solution with value $value found \e[00m")
            if value <= UB
                global UB = value
                global bestsol = calculate_sol(solution,node_pool)
            end
            # Delete nodes which can't have a better solution (lb >= UB)
            for i in 1:length(queue)-1
                if tree[queue[i]].lb >= UB
                    push!(nodestobedeleted,i)
                end
            end
        end

        # Solve slave problem
        reduced_cost, column = solve_slave(π,nodeindex)

        # Bound update
        nodeub = value
        nodelb = sum(π[i] for i in 1:data.N) + reduced_cost
        if nodelb >= tree[nodeindex].lb tree[nodeindex].lb = nodelb end

        if reduced_cost < Inf
            # Branching rules don't make the slave problem infeasible
            pattern = findall(x -> x!=0, column)
            if reduced_cost < -ϵ
                # Column is added to the master problem
                column_cost = 1
                push!(column_pool, vcat(column_cost,round.(column)))
                push!(node_pool, vcat(column_cost,round.(column)))
                push!(alpha, @variable(master,lower_bound=0))
                set_name(alpha[end], "alpha_$(size(column_pool,1))")
                for i in 1:data.N
                    set_normalized_coefficient(packed[i], alpha[end], column[i])
                end
                set_objective_function(master, objective_function(master) + column_cost*alpha[end])
                println("\e[34m Pattern with items $pattern added \e[00m")
            end
        else
            # Branching rules make the slave problem infeasible
            node_infeasible = true
            println("\e[36m Branching rules made the node infeasible \e[00m")
            break
        end

        if node_infeasible return [] end

        if (2*abs((nodeub-tree[nodeindex].lb))/abs((nodeub+tree[nodeindex].lb))<ϵ) || (reduced_cost>=-ϵ)
            if solution[1] >= ϵ
                # Artificial column is used in the solution
                node_infeasible = true
                println("\e[36m Artificial column used, node is infeasible \e[00m")
                return []
            end
            println("\e[36m Node relaxation is solved to optimality")
            println(" Node upper bound is $nodeub, Node lower bound is $(tree[nodeindex].lb) \e[00m")
            return calculate_sol(solution, node_pool)
        end
        optimize!(master)
    end
end

function calculate_columns(nodeindex)
    # Keep only columns satisfying current branching constraints
    node_pool = Array{Array{Int,1},1}()
    # Artificial pattern
    push!(node_pool, column_pool[1])
    for c in 2:size(column_pool,1)
        add = true
        for (i,j) in tree[nodeindex].upbranch
            if column_pool[c][i+1] != column_pool[c][j+1]
                add = false
                break
            end
        end
        add && break
        for (i,j) in tree[nodeindex].downbranch
            if column_pool[c][i+1] + column_pool[c][j+1] > 1
                add = false
                break
            end
        end
        add && break
        if add
            push!(node_pool,column_pool[c])
        end
    end
    return node_pool
end

function calculate_sol(mastersol, node_pool)
    # Pattern selected is the master solution with coefficient in first index
    x = Array{Array{Float32},1}()
    for c in 1:size(mastersol,1)
        if mastersol[c] >= ϵ push!(x, vcat(mastersol[c],node_pool[c][2:data.N+1])) end
    end
    return x
end

include("master.jl")
include("subproblem_generic.jl")

function process_node_generic(nodeindex)

    global branching_schemes = calculate_branching_schemes(nodeindex)

    if verbose_level>=3
        println("\e[93m Processing node $nodeindex \e[00m")
        println("\e[96m Up-branch pairs are : $(tree[nodeindex].upbranch)")
        println(" Down-branch pairs are : $(tree[nodeindex].downbranch)")
        println(" Number of subproblems : $(size(branching_schemes,1)) \e[00m")
    end

    global nodestobedeleted = []
    node_pool = calculate_columns(nodeindex, branching_schemes)

    packed, alpha, master = solve_master(node_pool)

    while true

        node_infeasible = false

        π = JuMP.dual.(packed)
        value = JuMP.objective_value(master)
        solution = JuMP.value.(alpha)

        if maximum(solution - floor.(solution)) <= ϵ
            if verbose_level>=3 println("\e[35m Feasible solution with value $value found \e[00m") end
            if value <= UB
                global UB = value
                global bestsol = calculate_sol(solution,node_pool)
            end
            for i in 1:length(queue)-1
                if tree[queue[i]].lb >= UB
                    push!(nodestobedeleted,i)
                end
            end
        end

        nodeub = value
        nodelb = sum(π)
        min_reduced_cost = 0

        for s in 1:size(branching_schemes,1)
            reduced_cost, column = solve_subproblem_generic(s,π,nodeindex)
            if reduced_cost < Inf
                pattern = findall(x -> x!=0, column)
                if reduced_cost<=min_reduced_cost min_reduced_cost=reduced_cost end
                if reduced_cost < -ϵ
                    column_cost = 1
                    push!(column_pool, vcat(column_cost,round.(column)))
                    push!(node_pool, vcat(column_cost,round.(column)))
                    push!(alpha, @variable(master,lower_bound=0))
                    set_name(alpha[end], "alpha_$(size(column_pool,1))")
                    for i in 1:data.N
                        set_normalized_coefficient(packed[i], alpha[end], column[i])
                    end
                    set_objective_function(master, objective_function(master) + column_cost*alpha[end])
                    if verbose_level>=3 println("\e[34m Pattern with items $pattern added \e[00m") end
                end
                nodelb += reduced_cost
            end
        end

        if node_infeasible return [] end

        if nodelb >= tree[nodeindex].lb tree[nodeindex].lb = nodelb end

        if (2*abs((nodeub-tree[nodeindex].lb))/abs((nodeub+tree[nodeindex].lb))<ϵ) || (min_reduced_cost>=-ϵ)
            if solution[1] >= ϵ
                # Artificial column is used in the solution
                if verbose_level>=3 println("\e[36m Artificial column used, node is infeasible \e[00m") end
                return []
            end
            if verbose_level>=3
                println("\e[36m Node relaxation is solved to optimality")
                println(" Node upper bound is $nodeub, Node lower bound is $(tree[nodeindex].lb) \e[00m")
            end
            return calculate_sol(solution, node_pool)
        end
        optimize!(master)
    end
end

function calculate_sol(mastersol, node_pool)
    # Pattern selected is the master solution with coefficient in first index
    x = Array{Array{Float32},1}()
    for c in 1:size(mastersol,1)
        if mastersol[c] >= ϵ push!(x, vcat(mastersol[c],node_pool[c][2:data.N+1])) end
    end
    return x
end

function calculate_branching_schemes(nodeindex)

    branching_schemes = Vector{Branching_Scheme}()
    push!(branching_schemes, Branching_Scheme([],[]))

    for (item1,item2) in tree[nodeindex].upbranch
        for b in 1:size(branching_schemes,1)
            push!(branching_schemes, Branching_Scheme(branching_schemes[b].setzero, unique(vcat(branching_schemes[b].setone,[item1,item2]))))
            branching_schemes[b].setzero = unique(vcat(branching_schemes[b].setzero,[item1,item2]))
        end
    end

    for (item1,item2) in tree[nodeindex].downbranch
        for b in 1:size(branching_schemes,1)
            push!(branching_schemes, Branching_Scheme(unique(vcat(branching_schemes[b].setzero,item2)), unique(vcat(branching_schemes[b].setone,item1))))
            branching_schemes[b].setzero = unique(vcat(branching_schemes[b].setzero,item1))
        end
    end

    to_delete = []
    for s in 1:size(branching_schemes,1)
        for i in 1:data.N
            if (i in branching_schemes[s].setzero) && (i in branching_schemes[s].setone)
                push!(to_delete, s)
                break
            end
        end
    end
    deleteat!(branching_schemes, to_delete)

    return branching_schemes
end

function calculate_columns(nodeindex, branching_schemes)

    node_pool = Array{Array{Int,1},1}()
    push!(node_pool, column_pool[1])

    for c in 2:size(column_pool,1)
        add = true
        for scheme in branching_schemes
            for i in scheme.setzero
                if column_pool[c][i+1] != 0
                    add = false
                    break
                end
            end
            if add
                for i in scheme.setone
                    if column_pool[c][i+1] != 1
                        add = false
                        break
                    end
                end
            end
        end
        if add
            push!(node_pool,column_pool[c])
        end
    end
    return node_pool
end

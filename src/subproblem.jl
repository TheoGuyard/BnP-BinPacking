include("knapsack.jl")

function solve_subproblem(nodeindex, rule, π)
    """Redirect to the chosen solving method."""

    if subproblem_method == "gurobi"
        cost, solution =  solve_subproblem_gurobi(nodeindex, rule, π)
    elseif subproblem_method == "dynamic"
        if branching_rule == "generic"
            cost, solution =  solve_subproblem_generic_dynamic(nodeindex, rule, π)
        elseif branching_rule == "ryan_foster"
            error("Not implemented yet")
        end
    end

    return cost, solution

end


function solve_subproblem_gurobi(nodeindex, rule, π)
    """Solving subproblem with Gurobi solver."""

    subproblem = Model(with_optimizer(Gurobi.Optimizer, GUROBI_ENV, OutputFlag = 0))

    # Basic subproblem problem
    @variable(subproblem, y[i in 1:data.N], Bin)
    @constraint(subproblem, capacity, sum(data.S[i] * y[i] for i = 1:data.N) <= data.C)
    @objective(subproblem, Min, 1 - sum(π[i] * y[i] for i = 1:data.N))

    # Branching constraints depending on the branching rule
    if branching_rule == "generic"
        for i in rule.setzero
            @constraint(subproblem, y[i] == 0)
        end
        for i in rule.setone
            @constraint(subproblem, y[i] == 1)
        end
    elseif branching_rule == "ryan_foster"
        for (i, j) in tree[nodeindex].upBranch
            @constraint(subproblem, y[i] == y[j])
        end
        for (i, j) in tree[nodeindex].downBranch
            @constraint(subproblem, y[i] + y[j] <= 1)
        end
    end

    optimize!(subproblem)

    if JuMP.termination_status(subproblem) == MOI.OPTIMAL
        return JuMP.objective_value(subproblem), JuMP.value.(y)
    else
        return Inf, []
    end

end


function solve_subproblem_generic_dynamic(nodeindex, rule, π)
    """Solve subproblem with dynamic programmation for the generic branching
    scheme (i.e solve knapsack problem)."""

    # Check if problem is feasible
    if length(intersect(rule.setzero, rule.setone)) > 0
        return Inf, []
    end

    capacity = copy(data.C)
    solution = zeros(data.N)

    # Preprocess the data with the subproblem rule (variables set to 0 and 1)
    index_not_used = []
    preprocess_cost = 0
    for i in rule.setzero
        push!(index_not_used, i)
    end
    for i in rule.setone
        push!(index_not_used, i)
        solution[i] = 1
        preprocess_cost += π[i]
        capacity -= data.S[i]
    end

    # Check if problem is feasible
    if capacity < 0
        return Inf, []
    end

    # Only keep undetermined variables
    knap_profits = π[filter(x -> !(x in index_not_used), eachindex(π))]
    knap_weights = data.S[filter(x -> !(x in index_not_used), eachindex(data.S))]

    knap_cost, knap_solution = solve_knapsack(knap_profits, knap_weights, capacity)
    cost = 1 - (knap_cost + preprocess_cost)
    solution[filter(x -> !(x in index_not_used), eachindex(solution))] = knap_solution
    if size(solution,1) != data.N
        error("Length")
    end
    return cost, solution

end

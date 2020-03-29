function solve_subproblem_ryan_foster(π, node)

    subproblem = Model(with_optimizer(Gurobi.Optimizer, GUROBI_ENV, OutputFlag = 0))

    # Basic subproblem problem
    @variable(subproblem, y[i in 1:data.N], Bin)
    @constraint(subproblem, capacity,
        sum(data.S[i] * y[i] for i in 1:data.N) <= data.C)
    @objective(subproblem, Min,
        1 - sum(π[i] * y[i] for i in 1:data.N))

    # Branching constraints
    for (i,j) in tree[node].upbranch
        @constraint(subproblem, y[i] == y[j])
    end
    for (i,j) in tree[node].downbranch
        @constraint(subproblem, y[i] + y[j] <= 1)
    end

    optimize!(subproblem)

    if JuMP.termination_status(subproblem) == MOI.OPTIMAL
        return JuMP.objective_value(subproblem), JuMP.value.(y)
    else
        return Inf, []
    end

end

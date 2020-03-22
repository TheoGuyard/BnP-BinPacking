function solve_slave(π, node)

    slave = Model(with_optimizer(Gurobi.Optimizer, GUROBI_ENV, OutputFlag = 0))

    # Basic slave problem
    @variable(slave, y[i in 1:data.N], Bin)
    @constraint(slave, capacity,
        sum(data.S[i] * y[i] for i in 1:data.N) <= data.C)
    @objective(slave, Min,
        1 - sum(π[i] * y[i] for i in 1:data.N))

    # Branching constraints
    for (i,j) in tree[node].upbranch
        @constraint(slave, y[i] == y[j])
    end
    for (i,j) in tree[node].downbranch
        @constraint(slave, y[i] + y[j] <= 1)
    end

    optimize!(slave)

    if JuMP.termination_status(slave) == MOI.OPTIMAL
        return JuMP.objective_value(slave), JuMP.value.(y)
    else
        return Inf, []
    end

end

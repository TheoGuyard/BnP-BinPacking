function solve_master(node_pool)

    master = Model(with_optimizer(Gurobi.Optimizer, GUROBI_ENV ,OutputFlag = 0))

    # alpha_p is the amount of the pattern p used
    alpha = @variable(master, alpha[p in 1:size(node_pool,1)], lower_bound=0)

    # Each item have to be packed once (>= 1 to be solved faster)
    packed = @constraint(master, packed[i in 1:data.N],
        sum(node_pool[p][i+1] * alpha[p] for p in 1:size(node_pool,1)) == 1)

    # Minimize the total number of pattern used
    @objective(master, Min,
        sum(alpha[p] * node_pool[p][1] for p in 1:size(node_pool,1)))
    optimize!(master)

    return packed, alpha, master

end

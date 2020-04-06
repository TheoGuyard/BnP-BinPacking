include("display.jl")

function solve_MIP()
    """Formulation and resolution and of the BPP problem."""

    println("\e[92m********** Solve MIP ****************\e[00m")

    model = Model(with_optimizer(Gurobi.Optimizer, GUROBI_ENV, OutputFlag = 0))

    # u_b = 1 if bin b is used and u_b = 0 otherwise
    @variable(model, u[b in 1:data.B], Bin)
    # x_ib = 1 if item if is parcked in bin b and x_ib = 0 otherwise
    @variable(model, x[i in 1:data.N, b in 1:data.B], Bin)

    # Packing constraint
    @constraint(model, packed[i in 1:data.N], sum(x[i, b] for b = 1:data.B) >= 1)
    # Capacity constraint
    @constraint(
        model,
        capacity[b in 1:data.B],
        sum(x[i, b] * data.S[i] for i = 1:data.N) <= u[b] * data.C
    )

    @objective(model, Min, sum(u[b] for b = 1:data.B))

    println("\e[37mSolving problem ... \e[00m")
    optimize!(model)

    obj = JuMP.objective_value(model)
    u = JuMP.value.(u)
    x = JuMP.value.(x)
    status = JuMP.termination_status(model)
    solvingTime = round(JuMP.solve_time(model))

    display_mip_result(obj, u, x, status, solvingTime)
    return nothing
end

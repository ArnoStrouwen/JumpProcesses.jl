using DiffEqJump, DiffEqBase
# using BenchmarkTools
using Test, LightGraphs

Nsims        = 100
reltol       = 0.05
non_spatial_mean = [65.7395, 65.7395, 434.2605] #mean of 10,000 simulations

dim = 1
linear_size = 5
dims = Tuple(5)
starting_site = trunc(Int,(linear_size^dim + 1)/2)
u0 = [500,500,0]
end_time = 10.0
diffusivity = 1.0

domain_size = 1.0 #μ-meter
mesh_size = domain_size/linear_size
# ABC model A + B <--> C
num_species = 3
reactstoch = [[1 => 1, 2 => 1],[3 => 1]]
netstoch = [[1 => -1, 2 => -1, 3 => 1],[1 => 1, 2 => 1, 3 => -1]]
rates = [0.1/mesh_size, 1.]
majumps = MassActionJump(rates, reactstoch, netstoch)

# spatial system setup
hopping_rate = diffusivity * (linear_size/domain_size)^2
num_nodes = 5

# Starting state setup
starting_state = zeros(Int, length(u0), num_nodes)
starting_state[:,starting_site] .= u0

tspan = (0.0, end_time)
prob = DiscreteProblem(starting_state, tspan, rates)
hopping_constants = [hopping_rate for i in starting_state]
alg = NSM()

function get_mean_end_state(jump_prob, Nsims)
    end_state = zeros(size(jump_prob.prob.u0))
    for i in 1:Nsims
        sol = solve(jump_prob, SSAStepper())
        end_state .+= sol.u[end]
    end
    end_state/Nsims
end

# testing on CartesianGrid
grids = [DiffEqJump.CartesianGrid1(dims), DiffEqJump.CartesianGrid2(dims), DiffEqJump.CartesianGrid3(dims), LightGraphs.grid(dims)]
jump_problems = JumpProblem[JumpProblem(prob, alg, majumps, hopping_constants=hopping_constants, spatial_system = grid, save_positions=(false,false)) for grid in grids]
# setup flattenned jump prob
graph = LightGraphs.grid(dims)
hopping_constants = Vector{Matrix{Float64}}(undef, num_nodes)
for site in 1:num_nodes
    hopping_constants[site] = hopping_rate*ones(num_species, DiffEqJump.num_neighbors(graph, site))
end
push!(jump_problems, JumpProblem(prob, NRM(), majumps, hopping_constants=hopping_constants, spatial_system = graph, save_positions=(false,false)))
# test
for spatial_jump_prob in jump_problems
    solution = solve(spatial_jump_prob, SSAStepper())
    mean_end_state = get_mean_end_state(spatial_jump_prob, Nsims)
    mean_end_state = reshape(mean_end_state, num_species, num_nodes)
    diff =  sum(mean_end_state, dims = 2) - non_spatial_mean
    for (i,d) in enumerate(diff)
        @test abs(d) < reltol*non_spatial_mean[i]
    end
end

#using non-spatial SSAs to get the mean
# non_spatial_rates = [0.1,1.0]
# reactstoch = [[1 => 1, 2 => 1],[3 => 1]]
# netstoch = [[1 => -1, 2 => -1, 3 => 1],[1 => 1, 2 => 1, 3 => -1]]
# majumps = MassActionJump(non_spatial_rates, reactstoch, netstoch)
# non_spatial_prob = DiscreteProblem(u0,(0.0,end_time), non_spatial_rates)
# jump_prob = JumpProblem(non_spatial_prob, Direct(), majumps)
# non_spatial_mean = get_mean_end_state(jump_prob, 10000)

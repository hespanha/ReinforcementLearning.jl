using Flux
using ReinforcementLearningEnvironments
using ReinforcementLearning

n_atoms = 51

env = CartPoleEnv()
ns, na = length(observation_space(env)), length(action_space(env))
model = Chain(Dense(ns, 128, relu), Dense(128, 128, relu), Dense(128, na * n_atoms))

target_model = Chain(Dense(ns, 128, relu), Dense(128, 128, relu), Dense(128, na * n_atoms))

Q = NeuralNetworkQ(model, ADAM(0.0005))
Qₜ = NeuralNetworkQ(target_model, ADAM(0.0005))

function logitcrossentropy_expand(logŷ::AbstractVecOrMat, y::AbstractVecOrMat)
    return vec(-sum(y .* logsoftmax(logŷ), dims = 1))
end

agent = Agent(
    QBasedPolicy(
        RainbowLearner(
            approximator = Q,
            target_approximator = Qₜ,
            loss_fun = logitcrossentropy_expand,
            γ = 0.99f0,
            Vₘₐₓ = 200.0f0,
            Vₘᵢₙ = 0.0f0,
            n_actions = na,
            n_atoms = n_atoms,
            target_update_freq = 100,
        ),
        EpsilonGreedySelector{:exp}(ϵ_stable = 0.01, decay_steps = 500),
    ),
    circular_PRTSA_buffer(
        capacity = 10000,
        state_eltype = Vector{Float64},
        state_size = (ns,),
    ),
)

hook = TotalRewardPerEpisode()

run(agent, env, StopAfterStep(10000); hook = hook)
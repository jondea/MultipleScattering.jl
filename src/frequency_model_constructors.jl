"""
Constructor which takes volfrac, particle radius and k_arr along with a load of
optional keyword arguments. This constructor automtically generates random
particles inside a shape (default to a square Rectangle with 4 particles) then
generates the response.
"""
function FrequencyModel{T}(volfrac::Number, radius::T, k_arr::Vector{T};
        source_direction=[one(T), zero(T)],
        c = one(Complex{T}),
        ρ = one(T),
        listener_positions = [-10one(T), zero(T)],
        source_position = [-10one(T), zero(T)],
        num_particles = 4,
        shape = Rectangle(volfrac, radius, num_particles),
        hankel_order = 3,
        seed = Base.Random.make_seed(),
        generate_responses=true
    )

    # Get the seed from the Twister so its definitely of type Vector{UInt32}
    seed = MersenneTwister(seed).seed
    particles = random_particles(volfrac, radius, shape; seed = seed)

    if isa(listener_positions,Vector)
        listener_positions = reshape(listener_positions, 2, 1)
    end

    response = Matrix{Complex{T}}(size(k_arr, 1), size(listener_positions, 2))
    model = FrequencyModel{T}(
        shape, ρ, c, particles,
        response, hankel_order,
        k_arr, listener_positions,
        source_position, source_direction,
        seed
    )
    if generate_responses generate_responses!(model, k_arr) end
    return model
end

"""
Constructor which takes a vector of particles, k_arr and a load of optional
keyword arguments. This constructor automtically generates the response.
"""
function FrequencyModel{T}(particles::Vector{Particle{T}}, k_arr::Vector{T};
        source_direction = [one(T), zero(T)],
        c = one(Complex{T}),
        ρ = one(T),
        listener_positions = reshape([-10one(T), zero(T)], 2, 1),
        source_position = [-10one(T), zero(T)],
        shape = Rectangle(particles),
        hankel_order = 3,
        seed = Vector{UInt32}(0),
        generate_responses=true
    )
    if isa(listener_positions, Vector)
        listener_positions = reshape(listener_positions, 2, 1)
    end
    response = Matrix{Complex{T}}(size(k_arr, 1), size(listener_positions, 2))
    model = FrequencyModel{T}(
        shape, ρ, c, particles,
        response, hankel_order,
        k_arr, listener_positions,
        source_position, source_direction,
        seed
    )
    if generate_responses generate_responses!(model, k_arr) end
    return model
end

"Take model parameters, run model and populate the response array."
function generate_responses!{T}(model::FrequencyModel{T},k_arr::Vector{T})
    model.response = Matrix{Complex{T}}(size(k_arr, 1), size(model.listener_positions, 2))
    # Map each k in k_arr over a the response function
    for i=1:length(k_arr)
        model.response[i,:] = response(model,k_arr[i])
    end
end

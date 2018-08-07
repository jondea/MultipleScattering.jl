import Base.Test: @testset, @test, @test_throws
import StaticArrays: SVector

using MultipleScattering

@testset "Time Result" begin
    sound_p = Acoustic(.1, 0.1 + 0.0im,2)
    particles = [Particle(sound_p,Circle([10.5,0.0], .5))]

    sound_sim = Acoustic(1., 1. + 0.0im,2)
    source = plane_source(sound_sim, [0.0,0.0], [1.0,0.0], 1.)
    sim = FrequencySimulation(sound_sim, particles, source)

    ω_vec = 0.0:0.01:5.01
    @test ω_vec == t_to_ω(ω_to_t(ω_vec)) # only exact for length(ω_vec) = even number

    # invertability of dft
        x_vec = [ [0.0,0.0], [3.0,0.0]]
        ω_vec = 0.0:0.1:1.01
        t_vec = 0.0:0.1:1.01
        simres = run(sim, x_vec, ω_vec)
        # choose an impulse which does nothing and so can be inverted
        discrete_impulse = DiscreteTimeDiracImpulse(0.0, t_vec, ω_vec)
        timres = frequency_to_time(simres; method=:dft, discrete_impulse = discrete_impulse)
        simres2 = time_to_frequency(timres; method=:dft, discrete_impulse = discrete_impulse)

        @test norm(field(simres) - field(simres2)) / norm(field(simres)) < 1e-14
        timres2 = frequency_to_time(simres2; method=:dft, impulse = TimeDiracImpulse(0.0));
        @test norm(field(timres2) - field(timres))/norm(field(timres)) < 1e-14

    # test impulse consistency by seeing if we get the same result when going from freq to time, and when going from time to freq.
        impulse = GaussianImpulse(maximum(ω_vec))
        timres2 = frequency_to_time(simres; method=:dft, impulse = impulse)
        simres2 = time_to_frequency(timres; method=:dft, impulse = impulse)
        # invert without an impulse
        timres3 = frequency_to_time(simres2; method=:dft, discrete_impulse = discrete_impulse)
        @test norm(field(timres2) - field(timres3))/norm(field(timres2)) < 1e-14

    # Compare dft and trapezoidal integration
        ω_vec = 0.0:0.1:100.01 # need a high frequency to match a delta impluse function!
        simres = run(sim, x_vec, ω_vec)
        timres1 = frequency_to_time(simres; method=:trapezoidal, impulse = TimeDiracImpulse(0.0))
        timres2 = frequency_to_time(simres; method=:dft, discrete_impulse = DiscreteTimeDiracImpulse(0.0, ω_to_t(simres.ω)))
        @test norm(field(timres1) - field(timres2))/norm(field(timres1)) < 0.02

        ω_vec = 0.0:0.0001:2.01 # need a high sampling to match a delta impluse function!
        t_vec = 0.:0.5:20.
        simres = run(sim, x_vec, ω_vec)
        timres1 = frequency_to_time(simres; t_vec = t_vec, method=:trapezoidal, impulse = GaussianImpulse(maximum(simres.ω)))
        timres2 = frequency_to_time(simres; t_vec = t_vec, method=:dft, impulse = GaussianImpulse(maximum(simres.ω)))
        @test norm(field(timres1) - field(timres2))/norm(field(timres1)) < 2e-5
        # plot(timres1.t', [field(timres1)[1,:]-field(timres2)[1,:]])
end

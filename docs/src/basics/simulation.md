# Simulation of Pumas Models

## The `simobs` Function

Simulation of a `PumasModel` are performed via the `simobs` function. The function
is given by the values:

```julia
simobs(m,data,param,[randeffs];kwargs...)
```

The terms in the function call are:

- `m`: the `PumasModel`, either defined via the `@model` DSL or the function-based
  interface.
- `data`: either a `Subject` or a `Population`.
- `param`: a `NamedTuple` of parameters which conform to the `ParamSet` of the
  model.
- `randeffs`: an optional argument for the random effects for the simulation.
  If the random effects are not given, they are sampled as described in the
  model.
- `kwargs`: extra keyword arguments.

Additionally, the following keyword arguments can be used:

- `alg`: the type for which differential
  equation solver method to use. For example, `alg=Rodas5()` specifies the usage
  of the 5th order Rosenbrock method for ODEs described in the
  [DifferentialEquations.jl solver documentation page](http://docs.juliadiffeq.org/latest/solvers/ode_solve.html#Rosenbrock-Methods-1). Defaults to an automatic stiffness
  detection algorithm for ODEs.
- `ensemblealg`: the parallel algorithm to use internally for simulating a `Population`. The options are [derived from DifferentialEquations.jl](https://docs.sciml.ai/latest/features/ensemble/#EnsembleAlgorithms-1). The default is `EnsembleThreads()`.
- Any keyword argument in the DifferentialEquations.jl common solver arguments.
  These are documented on the [DifferentialEquations.jl common solver options page](http://docs.juliadiffeq.org/latest/basics/common_solver_opts.html).

The result of `simobs` function is a `SimulatedObservation` if the `data` was
`Subject` and a `SimulatedPopulation` if the `data` was a `Population`.

## Handling Simulated Returns

When running

```julia
sim = simobs(m,data,param)
```

`sim` is a `SimulatedObservation` which can be accessed via its fields. These
fields are:

- `subject`: the `Subject` used to generate the observation
- `times`: the times associated with the observations
- `observed`: the resulting observations of the simulation

If the `@model` DSL is used, then `observed` is a `NamedTuple` where the names
give the associated values. From the function-based interface, `observed` is
the chosen return type of the `observed` function in the model specification.

A `SimulatedPopulation` is a collection of `SimulatedObservation`s, and when
indexed like `sim[i]` it returns the `SimulatedObservation` of the `i`th
simulation subject.

## Visualizing Simulated Returns

These objects have automatic plotting and dataframe visualization. To plot
a simulation return, simply call plot on the output using
[Plots.jl](https://github.com/JuliaPlots/Plots.jl). For example, the following
will run a simulation and plot the observed variables:

```julia
obs = simobs(m,data,param)
using Plots
plot(obs)
```

By default this generates a plot for each derived variable. To choose which
variables to plot, the `obsnames` argument can be given which declares indices
or derived variable names to plot. For example, `plot(obs,obsnames=[:dv1,:dv2])`
would only plot the values `dv1` and `dv2`. In addition, all of the
[Plots.jl attributes](http://docs.juliaplots.org/latest/attributes/)
can be used in this `plot` command. For more information on using Plots.jl, please
see [the Plots.jl tutorial](http://docs.juliaplots.org/latest/tutorial/).
Note that if the simulated return is a `SimulatedPopulation`, then the plots
overlay the results of the various subjects.

To generate the DataFrame associated with the observed outputs, simply call
`DataFrame` on the simulated return. For example, the following builds the
tabular output from the returned object:

```julia
obs = simobs(m,data,param)
df = DataFrame(obs)
```

# Defining NLME models in Pumas
We provide two interfaces: a macro-based domain-specific language (DSL) and a function-based macro-free approach. In most instances, the DSL is appropriate to use, but for advanced users, the functional interface might be useful.

## The `@model` macro interface
The simplest way to define an NLME model in Julia is to use the `@model` macro. We can define the simplest model of them all, the empty model, as follows
```@meta
DocTestSetup = quote
    using Pumas
end
```
```julia
@model begin

end
```
This creates a model with no parameters, no covariates, no dynamics, ..., nothing! To populate the model, we need to include one of the possible model blocks. The possible blocks are:
- `@param`, fixed effects specifications
- `@random`, random effects specifications
- `@covariates`, covariate names
- `@pre`, pre-processing variables for the dynamic system and statistical specification
- `@vars`, shorthand notation
- `@init`, initial conditions for the dynamic system
- `@dynamics`, dynamics of the model
- `@derived`, statistical modeling of dependent variables
- `@observed`, model information to be stored in the model solution

The definitions in these blocks are generally only available in the blocks further down the list.

### `@param`: Fixed effects
The fixed effects, also called population parameters, are specified in the `@param` block. Parameters
are defined by an `in` (or ∈, written via \in) statement that connects a parameter name and a domain.
For example, to specify θ as a real scalar in a model, one would write:

```jldoctest
@model begin
  @param begin
    θ ∈ RealDomain(lower=0.0, upper=17.0)
  end
end

# output

PumasModel
  Parameters: θ
  Random effects: 
  Covariates: 
  Dynamical variables: 
  Derived: 
  Observed: 
```
which creates a model with a parameter that has a lower and upper bound on the allowed values.

!!! tip
   Pumas.jl does not expect specific names for parameters, dependent variables, and so on. This
   means that fixed effects do not have to be called θ, random effects don't have to be called η,
   variability (variance-covariance) matrices for random effects don't have to be called Ω, and so on
   Pick whatever is natural for your context.

Different domains are available for different purposes. Their names and purposes are

- `RealDomain` for scalar parameters
- `VectorDomain` for vectors
- `PDiagDomain` for positive definite matrices with diagonal structure
- `PSDDomain` for general positive semi-definite matrices

Different domains can be used when we want to have our parameters be scalars or vectors (`RealDomain` vs `VectorDomain`) or have certain properties (`PDiagDomain` and `PSDDomain`). The simplest way of specifying amodel is in terms of all scalar parameters
```jldoctest; output = false
@model begin
  @param begin
    θCL ∈ RealDomain(lower=0.001, upper=50.0)
    θV  ∈ RealDomain(lower=0.001, upper=500.0)
    ω²η ∈ RealDomain(lower=0.001, upper=20.0)
  end
end

# output

PumasModel
  Parameters: θCL, θV, ω²η
  Random effects: 
  Covariates: 
  Dynamical variables: 
  Derived: 
  Observed: 
```

where we have defined a separate variable for population clearance and volume as well as the variance of a scalar (univariate) random effect. The same model could be written using vectors and matrix type domains using something like the following

```jldoctest; output = false
@model begin
  @param begin
    θ  ∈ VectorDomain(2, lower=[0.001, 0.001], upper=[50.0, 500.0])
    Ωη ∈ PDiagDomain(1) # no lower or upper keywords!
  end
end

# output
PumasModel
  Parameters: θ, Ωη
  Random effects: 
  Covariates: 
  Dynamical variables: 
  Derived: 
  Observed: 
```

Notice, that we collapsed the two parameters `θCL` and `θV` into a single vector `θ`, and if we want to use the elements in the model you will have to use indexing `θ[1]` for `θCL` and `θ[2]` for `θV`. It is also necessary to specify the dimension of the vector which is two in this case. The `PDiagDomain` domain type is special. It makes `Ωη` have the interpretation of a matrix type, specifically a diagonal matrix. Additionally, it tells Pumas that when `fit`ing the multivariate parameter should be kept positive definite. The obvious use case here is variance-covariance matrices, and specifically it's useful for random effect vectors where each random effect is independent of the other. We will get back to this below.

Finally, we have the `PSDDomain`. This is different from `PDiagDomain` mainly by representing a "full" variance-covariance matrix. This means that one random effect can correlate with other random effects.

```jldoctest; output = false
@model begin
  @param begin
    θ ∈ VectorDomain(2, lower=[0.001, 0.001], upper=[50.0, 500.0])
    Ωη ∈ PSDDomain(1) # no lower upper!
  end
end

# output

PumasModel
  Parameters: θ, Ωη
  Random effects: 
  Covariates: 
  Dynamical variables: 
  Derived: 
  Observed: 
```

Besides actual domains, it is possible to define parameters in terms of their priors. A model with a parameter
that has a multivariate normal (`MvNormal`) prior can be defined as:

```jldoctest; output = false
μ_prior = [0.1, 0.3]
Σ_prior = [1.0 0.1
           0.1 3.0]
@model begin
  @param begin
    θ ~ MvNormal(μ_prior, Σ_prior)
  end
end

# output

PumasModel
  Parameters: θ
  Random effects: 
  Covariates: 
  Dynamical variables: 
  Derived: 
  Observed: 
```
A prior can be wrapped in a `Constrained(prior; lower=lv, upper=uv)`  to constrain values to be between `lv` and `uv`. See `?Constrained` for more details.

!!! tip
    Many of the NLME model definition portions require the specification of
    probability distributions. The distributions in Pumas are generally defined by the
    [Distributions.jl](https://juliastats.github.io/Distributions.jl/stable/) library.
    All of the Distributions.jl `Distribution` types are able to be used throughout
    the Pumas model definitions. Multivariate domains defines values which are
    vectors while univariate domains define values which are scalars. For the full
    documentation of the `Distribution` types, please see
    [the Distributions.jl documentation](https://juliastats.github.io/Distributions.jl/stable/)

### `@random`: Random effects

The novelty of the NLME approach comes from the individual variability. We just saw that `@param`
was used to specify fixed effects. The appropriate block for specifying random effects is simply called
`@random`. The parameters specified in this block can be scalar or vectors just as fixed parameters, but
they will always be defined by the distribution they are assumed to follow.

The parameters are defined by a `~` (read: distributed as) expression:

```jldoctest
@model begin
  @param begin
    ω²η ∈ RealDomain(lower=0.0001)
  end
  @random begin
    η ~ Normal(0, sqrt(ω²η))
  end
end

# output

PumasModel
  Parameters: ω²η
  Random effects: η
  Covariates: 
  Dynamical variables: 
  Derived: 
  Observed: 
```

We see that we defined a variability parameter `ω²η` to parameterize the variance of the univariate `Normal` distribution of the η. We put a lower bound of `0.0001` because a variance *cannot* be negative, and a variance of exactly zero would lead to a degenerate distribution. We always advise putting bounds on variables whenever possible. We also advise using the unicode `²` (\^2 + Tab) to show that it's a variance, though this is optional. The `Normal` distribution Distributions.jl requires two positional arguments: the mean (here: 0) and the standard deviation (here: the square root of our variance). For more details type `?Normal` in the REPL. It is, of course, possible to have as many univariate random effects as you want:

```jldoctest; output = false
@model begin
  @param begin
    Ωη ∈ VectorDomain(3, lower=0.0001)
  end
  @random begin
    η1 ~ Normal(0, sqrt(Ωη[1]))
    η2 ~ Normal(0, sqrt(Ωη[2]))
    η3 ~ Normal(0, sqrt(Ωη[3]))
  end
end

# output

PumasModel
  Parameters: Ωη
  Random effects: η1, η2, η3
  Covariates: 
  Dynamical variables: 
  Derived: 
  Observed: 
```

Notice the use of indexing into the `Ωη` parameter that is now a vector. Other ways of 
parameterizing random effects include vector (multivariate) distributions:

```jldoctest; output = false
@model begin
  @param begin
    Ωη ∈ VectorDomain(3, lower=0.0001)
  end
  @random begin
    η ~ MvNormal(sqrt.(Ωη))
  end
end

# output

PumasModel
  Parameters: Ωη
  Random effects: η
  Covariates: 
  Dynamical variables: 
  Derived: 
  Observed: 
```

where `η` will have a diagonal variance-covariance structure because we input a vector of standard deviations. This can also be
achieved using the `PDiagDomain` as we saw earlier and then we don't have to worry about the `lower` keyword

```jldoctest; output = false
@model begin
  @param begin
    Ωη ∈ PDiagDomain(3)
  end
  @random begin
    η ~ MvNormal(Ωη)
  end
end

# output

PumasModel
  Parameters: Ωη
  Random effects: η
  Covariates: 
  Dynamical variables: 
  Derived: 
  Observed: 
```

Do notice that `Ωη` is not to be considered a vector here, but an actual diagonal matrix, so `Ωη` is now the (diagonal) variance-covariance matrix, not a vector of standard deviations. The `@random` block is the same if we allow full covariance structure:

```jldoctest; output = false
@model begin
  @param begin
    Ωη ∈ PSDDomain(3)
  end
  @random begin
    η ~ MvNormal(Ωη)
  end
end

# output

PumasModel
  Parameters: Ωη
  Random effects: η
  Covariates: 
  Dynamical variables: 
  Derived: 
  Observed: 
```

For cases where you have several random effects with the exact same distribution, such as between-occasion-variability (BOV), it is convenient to construct a single vector η that has diagonal variance-covariance structure with identical variances down the diagonal. This can be achieved using a special constructor that takes in the dimension and the standard deviation

```jldoctest; output = false
@model begin
  @param begin
    ω²η ∈ RealDomain(lower=0.0001)
  end
  @random begin
    η ~ MvNormal(4, sqrt(ω²η))
  end
end

# output

PumasModel
  Parameters: ω²η
  Random effects: η
  Covariates: 
  Dynamical variables: 
  Derived: 
  Observed: 
```

You could use four scalar `η`'s as shown above, but for BOV it is useful to encode the occasions using integers 1, 2, 3, ..., N and simply index into `η` using `η[OCC]` where `OCC` is the occasion covariate.

### `@covariates`
The covariates in the model have to be specified in the `@covariates` block. This information is used to
generate efficient code for expanding covariate information from each subject when solving the model or
evaluating likelihood contributions from observations. The format is simply to either use a block

```jldoctest
@model begin
  @covariates begin
    weight
    age
    OCC
  end
end

# output

PumasModel
  Parameters: 
  Random effects: 
  Covariates: weight, age, OCC
  Dynamical variables: 
  Derived: 
  Observed: 
```
   
or a one-liner

```jldoctest
@model begin
  @covariates weight age OCC
end

# output

PumasModel
  Parameters: 
  Random effects: 
  Covariates: weight, age, OCC
  Dynamical variables: 
  Derived: 
  Observed: 
```

### `@pre`: Pre-processing of input to dynamics and derived

Before we move to the actual dynamics of the model (if there are any) and the statistical model
of the observed variables we need to do some preprocessing of parameters and covariates to get 
our rates and variables ready for our ODEs or distributions. This is done in the `@pre` block.

In the `@pre` block all calculations are written as if they happen at some arbitrary point in 
time `t`. Let us see an example
```julia
@model begin
  # Fixed parameters  
  @param begin
    θCL ∈ RealDomain(lower=0.0001, upper=20.0)
    θV  ∈ RealDomain(lower=0.0001, upper=91.0)
    θbioav ∈ RealDomain(lower=0.0001, upper=1.0)
    ω²η ∈ RealDomain(lower=0.0001)
  end

  # Random parameters
  @random begin
    η ~ MvNormal(4, sqrt(ω²η))
  end

  # Covariate enumeration  
  @covariates weight age OCC

  # Preprocessing of input to dynamics and derived
  @pre begin
    CL = θCL*sqrt(weight)/age + η[OCC]
    V = θV*sin(t)
    bioav = (Depot=θbioav, Central=0.4)
  end
end
```

We see that when we assign the right-hand side to `CL`, it involves weight, age and occasion counter, OCC. These might all be recorded as time-varying, especially the last one. The first line of `@pre` then means that whenever `CL` is referenced in the dynamic model or in the statistical model it will have been calculated with the covariates evaluated at the appropriate time. The next line that defines the volume of distribution, `V`, shows this by explicitly using `t` (a reserved keyword) to model `V` as something that varies with time.

The last line we see is special as it uses what is called a dose control parameter (DCP). The line sets bioavailability for a `Depot` compartment to a parameter in our model `θbioav`, and bioavailability of another compartment `Central` to a fixed value of 0.4. If a compartment is not mentioned in the `NamedTuple` it will be set to 1.0. Other DCPs are: `lags`, `rate`, and `duration`. 

!!! tip
    The dose control parameters are entered as `NamedTuple`s. If a DCP is just set for one-compartment to have the rest default to 1.0 it is a common mistake to write `rate = (Depot=θ)` instead of `rate = (Depot=θbioav,)`. Notice the trailing `,` in the second expression which is required to construct a `NamedTuple` in Julia.

### `@vars`: Short-hand notation
Suppose we have a model with a dynamic variable `Central` and a volume of dispersion `V`. You can define short-hand notation for the implied plasma concentration to be used elsewhere in the model in `@vars`: 

```julia
@model begin
  ...
  @vars begin
    conc = Central/V
  end
end
```

While some users find `@vars` useful we advise users to use it with caution. Short-hand notation involving dynamic variables might make the `@dynamics` block harder to read. Short-hand notation that doesn't not involve dynamic variables should rather just be specified in `@pre`. 

### `@init`: Initializing the dynamic system
This block defines the initial conditions of the dynamical model in terms of the parameters, random effects, and pre-processed variables. It is defined by a series of equality (=) statements. For example, to set the initial condition of the Response dynamical variable to be the value of the 5th term of the parameter θ, we would use the syntax:

```julia
@model beign
  @param begin
    θ ∈ VectorDomain(3, lower=[0.0,0.0,1.0], upper=[3.0,1.0,4.0])
  end
  @init begin
    Depot = θ[2]
  end
end
```
Any variable omitted from this block is given the default initial condition of 0. If the block is omitted, then all dynamical variables are initialized at 0.

Note that the special value := can be used to define intermediate statements that will not be carried outside of the block.

### `@dynamics`: The dynamic model


The @dynamics block defines the nonlinear function from the parameters to the derived variables via a dynamical (differential equation) model. It can currently be specified either by an analytical solution type, an ordinary differential equation (ODE) or a combination of the two (for more types of differential equations, please see the function-based interface).

The analytical solutions are defined in the [Dynamical Problem Types](@ref) page and can be invoked via the name. For example,

```julia
@model begin
  @param begin
    θCL ∈ RealDomain(lower=0.001, upper=10.0)
    θVc ∈ RealDomain(lower=0.001, upper=10.0)
  end

  @pre begin
    CL = θCL
    Vc = θVc
  end

  @dynamics Central1
end
```
defines the dynamical model as the one compartment model `Central1` represents. The model has two required parameters: `CL` and `Vc`. These have to be defined in `@pre` when this model is used. All models with analytical solutions have the required parameters listed in their docstring which can be seen by typing `?Central1` in the REPL. Alternatively, it is listed in the documentation on the [Analytical Problems](@ref) page.

For a system of ODEs that has to be numerically solved, the dynamical variables are defined by their derivative expression. A derivative expression is given by a variable's derivative (specified by ') and an equality (=). For example, the following defines a model equivalent to the model above:

```julia
@model begin
  @param begin
    θCL ∈ RealDomain(lower=0.001, upper=10.0)
    θVc ∈ RealDomain(lower=0.001, upper=10.0)
  end

  @pre begin
    CL = θCL
    Vc = θVc
  end

  @dynamics begin
    Central' = -CL/Vc*Central
  end
end
```

Variable aliases defined in the @vars are accessible in this block. Additionally, the variable t is reserved for the solver time if you want to use something like `sin(t)` in your model formulation.

Note that any Julia function defined outside of the @model block can be invoked in the @dynamics block.


### `@derived`: Statistical modeling of observed variables
This block is used to specify the assumed distributions of observed variables that are derived from
the blocks above. All variables are referred to as the subject's observation times which means they are vectors.
This means we have to use "dot calls" on functions of dynamic variables, parameters, variables from `@pre`, etc.

```julia
@model begin
  @param begin
    θCL ∈ RealDomain(lower=0.001, upper=10.0)
    θVc ∈ RealDomain(lower=0.001, upper=10.0)
    ω²η ∈ RealDomain(lower=0.001, upper=20.0)
  end

  @pre begin
    CL = θCL
    Vc = θVc
  end

  @dynamics begin
    Central' = -CL/Vc*Central
  end

  @derived begin
    cp := @. Central/Vc
    dv ~ @. Normal(cp, sqrt(ω²η))
  end
end
```

We define `cp` (concentration in plasma) using `:=` which means that the variable `cp` will not be stored in the output you get when evaluating the model's `@derived` block. In many cases it is easier to simply write it out like this:

```julia
@derived begin
  dv ~ @. Normal(Central/Vc, sqrt(ω²η))
end
```

This will be slightly faster. However, sometimes it might be helpful to use `:=` for intermediary calculations in complicated expressions.

### `@observed`: Sampled observations

If you wish to store some information from the model solution or calculate a variable based on the model solutions and parameters that has nothing to do with the statistical modeling it is useful to define these variables in the `@observed` block. A simple example could be that you want to store a scaled plasma concentration. This could be written like the following:


```julia
@model begin
  @param begin
    θCL ∈ RealDomain(lower=0.001, upper=10.0)
    θVc ∈ RealDomain(lower=0.001, upper=10.0)
    ω²η ∈ RealDomain(lower=0.001, upper=20.0)
  end

  @pre begin
    CL = θCL
    Vc = θVc
  end

  @dynamics begin
    Central' = -CL/Vc*Central
  end

  @observed begin
    cp1000 = @. 1000*Central/Vc
  end
end
```

which will cause functions like `simobs` to store the simulated plasma concentration multiplied by a thousand.


## The PumasModel Function-Based Interface

The `PumasModel` function-based interface for defining an NLME model is the most
expressive mechanism for using Pumas and directly utilizes Julia types and
functions. In fact, under the hood, the `@model` DSL works by building an
expression for the `PumasModel` interface! A `PumasModel` has the constructor:

```julia
PumasModel(
  paramset,
  random,
  pre,
  init,
  prob,
  derived,
  observed=(col,sol,obstimes,samples,subject)->samples)
```

Notice that the `observed` function is optional. 

This section describes the API of the functions which make up the `PumasModel` type.
The structure closely follows that of the `@model` macro but is more directly Julia syntax.
Only `observed` is optional as opposed to the DSL where we could omit certain blocks and
have Pumas automatically fill in blank objects for us.

### The `paramset` ParamSet

The value `paramset` is a `ParamSet` object which takes in a named tuple of `Domain` or
distribution types. The allowed types are defined and explained on the [Domains](@ref) page. For example,
the following is a valid `ParamSet` construction:

```jldoctest; output = false
paramset = ParamSet((θ = VectorDomain(4, lower=zeros(4)), # parameters
              Ω = PSDDomain(2),
              Σ = RealDomain(lower=0.0)))

# output

ParamSet{NamedTuple{(:θ, :Ω, :Σ),Tuple{VectorDomain{Array{Float64,1},Array{TransformVariables.Infinity{true},1},Array{Float64,1}},PSDDomain{Array{Float64,2}},RealDomain{Float64,TransformVariables.Infinity{true},Float64}}}}((θ = VectorDomain{Array{Float64,1},Array{TransformVariables.Infinity{true},1},Array{Float64,1}}([0.0, 0.0, 0.0, 0.0], [TransformVariables.Infinity{true}(), TransformVariables.Infinity{true}(), TransformVariables.Infinity{true}(), TransformVariables.Infinity{true}()], [0.0, 0.0, 0.0, 0.0]), Ω = PSDDomain{Array{Float64,2}}([1.0 0.0; 0.0 1.0]), Σ = RealDomain{Float64,TransformVariables.Infinity{true},Float64}(0.0, TransformVariables.Infinity{true}(), 0.0)))
```

### The `random` Function

The `random(param)` function is a function of the parameters. It takes in the
values from the `param` input named tuple and outputs a `ParamSet` for the
random effects. For example:

```julia
function random(p)
    ParamSet((η=MvNormal(p.Ω),))
end
```

is a valid `random` function.

### The `pre` Function

The `pre` function takes in the `param` named tuple, the sampled `randeffs`
named tuple, and the `subject` data and defines the named tuple of the collated
preprocessed dynamical parameters. For example, the following is a valid
definition of the `pre` function:

```julia
function pre(param,randeffs,subject)
  function pre_t(t)
    cov_t = subject.covariates(t)
    CL = param.θ[2] * ((cov_t.wt/70)^0.75) * (param.θ[4]^cov_t.sex) * exp(randeffs.η[1])
    return (Σ=param.Σ, Ka=param.θ[1], CL=CL, V=param.θ[3] * exp(randeffs.η[2]))
  end
end
```

Such that it spits out something that can be called with a point in time `t` and returns the pre-processed
variables at that time. Notice that the covariates are found as a function of `t` in the `subject.covariates` field.

#### Dosing Control Parameters

Special parameters in the return of the `pre` function, such as `lag`, are
used to control the internal event handling (dosing) system. For more
information on these parameters, see the [Dosing Control Parameters (DCP)](@ref) page.
If they are left out of the returned `NamedTupled` they assume their default values.

### The `init` Function

The `init` function defines the initial conditions of the dynamical variables
from the pre-processed values `col` and the initial time point `t0`.
Note that this follows the [DifferentialEquations.jl](http://docs.juliadiffeq.org/latest/)
convention, in that the initial value type defines the type for the state used
in the evolution equation.

For example, the following defines the initial condition to be a vector of two
zeros:

```julia
function init(col,t0)
   [0.0,0.0]
end
```

### The `prob` DEProblem

The `prob` is a `DEProblem` defined by [DifferentialEquations.jl](http://docs.juliadiffeq.org/latest/).
It can be any `DEProblem`, and the choice of `DEProblem` specifies the type of
dynamical model. For example, if `prob` is an `SDEProblem`, then the NLME
will be defined via a stochastic differential equation, and if `prob` is a
`DDEProblem`, then the NLME will be defined via a delay differential equation.
For details on defining a `DEProblem`, please
[consult the DifferentialEquations.jl documentation](http://docs.juliadiffeq.org/latest/).

Note that the timespan, initial condition, and parameters are sentinels that
will be overridden in the simulation pipeline. Thus, for example, we can
define `prob` as an `ODEProblem` omitting these values as follows:

```julia
function onecompartment_f(du,u,p,t)
    du[1] = -p.Ka*u[1]
    du[2] =  p.Ka*u[1] - (p.CL/p.V)*u[2]
end
prob = ODEProblem(onecompartment_f,nothing,nothing,nothing)
```

Notice that the parameters of the differential equation `p` is the result value
`pre`.

### The `derived` Function

The `derived` function takes in the collated preprocessed values `col`, the
`DESolution` to the differential equation `sol`, the `obstimes` set during
the simulation and estimation, and the full `subject` data. The output can be
any Julia type on which `map(f,x)` is defined (the `map` is utilized for the
subsequent sampling of the error models). For example, the following is a valid
`derived` function which outputs a named tuple:

```julia
function derived(col, sol, obstimes, subject)
    central = sol(obstimes;idxs=2)
    conc = @. central / col.V
    dv = @. Normal(conc, conc*col.Σ)
    (dv=dv,)
end
```

Note that probability distributions in the output have a special meaning in
maximum likelihood and Bayesian estimation, and are automatically sampled
to become observation values during simulation.

### The `observed` Function

The `observed` function takes in the collated preprocessed values `col`,
the `DESolution` `sol`, the `obstimes`, the sampled derived values `samples`,
and the full `subject` data. The output value is the simulation output. It can
be any Julia type. For example, the following is a valid `observed` function:

```julia
function observed(col,sol,obstimes,samples,subject)
    (obs_cmax = maximum(samples.dv),
     T_max = maximum(obstimes),
     dv = samples.dv)
end
```

Note that if the `observed` function is not given to the `PumasModel` constructor,
the default function `(col,sol,obstimes,samples,subject)->samples` which passes
through the sampled derived values is used.

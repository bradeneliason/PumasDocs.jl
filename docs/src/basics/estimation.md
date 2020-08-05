# Estimating Parameters of Pumas Models

Pumas can use the observational data of a `Subject` or `Population` to estimate
the parameters in many types of models. This is done by two classes of methods.
First, maximum likelihood methods find the parameters such that the observational
data has the highest probability of occurring according to the chosen error
distributions. Second, bayesian methods find a posterior probability distribution for
the parameters to describe the chance that a parameter has a given value given
the data. The following section describes how to fit an NLME model in Pumas
via the two methods.

    - Maximum likelihood methods find the parameters such that the observational
    data has the highest probability of occurring according to the chosen error
    distributions. 

    - Bayesian methods find a posterior probability distribution for
    the parameters to describe the chance that a parameter has a given value given
    the data. The following section describes how to fit an NLME model in Pumas
    via the two methods.

## Defining Data for Estimation

The observed data should be parsed using the name names as those found in the
model. For example, if `subject.observations` is a `NamedTuple` with names `dv` and
`resp`, the `derived` block or function in the model should define distributions with matching names.
If `dv` is a scalar in the observation data, then `dv`
from `derived` should also be a scalar. Likewise, if `dv` is an array like
a time series, then `dv` should be a size-matching time series when returned
from `derived`. The likelihood of observing multiple dependent variables is 
calculated under the assumtion of independence between the two.

## Maximum Likelihood Estimation

Maximum Likelihood Estimation (MLE) is performed using the `fit` function. This
function's signature is:

```julia
Distributions.fit(model::PumasModel,
                  data::Population,
                  param::NamedTuple,
                  approx::LikelihoodApproximation;
                  optimize_fn = DEFAULT_OPTIMIZE_FN,
                  constantcoef::NamedTuple = NamedTuple(),
                  omegas::Tuple = tuple(),
                  ensemblealg::DiffEqBase.EnsembleAlgorithm = EnsembleSerial(),
                  checkidentification=true,
                  kwargs...))
```

Fit the Pumas model `model` to the dataset `population` with starting values
`param` using the estimation method `approx`. Currently supported values for
the `approx` argument are `FO`, `FOCE`, `FOCEI`, `LaplaceI`, `TwoStage`,
`NaivePooled`, and `BayesMCMC`. See the online documentation for more details
about the different methods.

The argument `optimize_fn` is used for optimizing the objective function
for all `approx` methods except `BayesMCMC`. The default optimization function
uses the quasi-Newton routine `BFGS` method from the `Optim` package.
Optimization specific arguments can be passed to `DefaultOptimizeFN`, e.g. the
optimization trace can be disabled by passing
`DefaultOptimizeFN(show_trace=false)`. See `Optim` for more defails.

It is possible to fix one or more parameters of the fit by passing a
`NamedTuple` as the `constantcoef` argument with keys and values corresponding
to the names and values of the fixed parameters, e.g. `constantcoef=(σ=0.1,)`.

When models include an `@random` block and fitting with `NaivePooled` is
requested, it is required that the user supplies the names of the parameters
of the random effects as the `omegas` argument such that these can be ignored
in the optimization, e.g. `omegas=(Ω,)`.

Parallelization of the optimization is supported for most estimation methods
via the ensemble interface of DifferentialEquations.jl. The default is
`EnsembleSerial()`. Currently, the only supported parallelization for
model fitting is `EnsembleThreads()`.

The `fit` function will check if any gradients and throw an exception if any
of the elements are exactly zero unless `checkidentification` is set to `false`.

Further keyword arguments can be passed via the `kwargs...` argument. This
allows for passing arguments to the differential equations solver such as
`alg`, `abstol`, and `reltol`. The default values for these are
`AutoVern7(Rodas5())`, `1e-12`, and `1e-8` respectively. See the
DifferentialEquations.jl documentation for more details.

The return type of `fit` is a `FittedPumasModel`.

### Marginal Likelihood Approximations

The following choices are available for the likelihood approximations:

- `FO()`: first order approximation.
- `FOCE()`: first order conditional estimation.
- `FOCEI()`: first order conditional estimation with interaction.
- `LaplaceI()`: second order Laplace approximation with interaction.

### FittedPumasModel

The relevant fields of a `FittedPumasModel` are:

- `model`: the `model` used in the estimation process.
- `data`: the `Population` that was estimated.
- `optim`: the result returned by the optimizer
- `approx`: the marginal likelihood approximation that was used.
- `param`: the optimal parameters.

## Bayesian Estimation

Bayesian parameter estimation is performed by using the `fit` function as follows:

```julia
Distributions.fit(
    model::PumasModel,
    data::Population,
    param::NamedTuple,
    ::BayesMCMC;
    nadapts::Integer=2000,
    nsamples::Integer=10000,
    progress = Base.is_interactive,
    kwargs...
 )
```

!!! info
    
    We use a Generalised `NUTS` with multinomial sampling with a diagonal metric and Ordinary leapfrog integrator. 
    The adaptation is done using the Stan's windowed adaptation routine with a target acceptance ratio of `0.8`.  

The arguments are:

- `model`: a `PumasModel`, either defined by the `@model` DSL or the function-based
  interface.
- `data`: a `Population`.
- `param`: a named tuple of parameters. Used as the initial condition for the
  sampler.
- The `approx` must be `BayesMCMC()`.
- `nsamples` determines the number of samples taken along each chain.
- Extra `args` and `kwargs` are passed on to the internal `simobs` call and
  thus control the behavior of the differential equation solvers.

The result is a `BayesMCMCResults` type.

### BayesMCMCResults

The MCMC chain is stored in the `chain` field of the returned `BayesMCMCResults`.
Additionally the result can be converted into a `Chains` object from MCMCChains.jl,
allowing utlilization of diagnostics and visualization tooling. This is discussed further in
the Bayesian Estimation tutorial. 

The following functions help with querying common results on the Bayesian
posterior:

- `param_mean(br)`: returns a named tuple of parameters which represents the
  mean of each parameter's posterior distribution
- `param_var(br)`: returns a named tuple of parameters which represents the
  variance of each parameter's posterior distribution
- `param_std(br)`: returns a named tuple of parameters which represents the
  standard deviation of each parameter's posterior distribution

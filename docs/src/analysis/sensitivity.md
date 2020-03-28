# Global Sensitivity Analysis

Sensitivity analysis (SA) is the study of how uncertainty in the output of a model can be 
apportioned to different sources of uncertainty in the model input. A sensitivity analysis 
is considered to be global when all the input factors are varied simultaneously and the 
sensitivity is evaluated over the entire range of each input factor. It provides an overall 
view on the influence of inputs on outputs as opposed to a local view of partial derivatives 
as in local sensitivity analysis.

[DiffEqSensitivity.jl](https://docs.sciml.ai/dev/analysis/global_sensitivity/#gsa-1) currently 
provides the following global sensitivity analysis methods:

1. Morris OAT Method
2. Sobol Method
3. eFAST Method
4. Regression based sensitivity 
5. Derivative Based Global Sensitivity Measures

Global Sensitivity Analysis (GSA) is performed using the `gsa` function. This
function's signature is:

```julia
DiffEqSensitivity.gsa(m::PumasModel, population::Population, params::NamedTuple, method::DiffEqSensitivity.GSAMethod, 
                    vars = [:dv], p_range_low=NamedTuple{keys(params)}([par.*0.05 for par in values(params)]), 
                    p_range_high=NamedTuple{keys(params)}([par.*1.95 for par in values(params)]), 
                    args...; kwargs...)
```

The arguments are:

- `m`: a `PumasModel`, either defined by the `@model` DSL or the function-based
  interface.
- `population`: a `Population`.
- `params`: a named tuple of parameters. Used as the initial condition for the
  optimizer.
-  `method`: one of the `GSAMethod`s from DiffEqSensitivity.jl, `Sobol()`, `Morris()`, `eFAST()`, 
    `RegressionGSA()`. 
-  `vars`: a list of the derived variables to run GSA on.
-  `p_range_low` & `p_range_high`: the lower and upper bounds for the parameters.

For method specific arguments that are passed with the method constructor you can refer to the 
[DiffEqSensitivity.jl](https://docs.sciml.ai/dev/analysis/global_sensitivity/#gsa-1) documentation.

The `gsa` provided in Pumas assumes that you want to run GSA on all of the parameters of the model and
also constraints you to run GSA only on variable in the `@derived` block. For more control on the input
and output you can create a custom function and use the `gsa` function from DiffEqSensitivity.jl which is 
callable on any julia function directly.
# Domains

Domains are used to define the `param` portion of a `PumasModel`. This segment
of the documentation describes the available `Domain` types that can be used
within the `param` portions.

## Matching Parameter Types and Domains

A `param` specification in a `PumasModel` directly defines the types which are
required to be given as the input to the model's API functions such as `simobs`
and `fit`. For example, if the `param` specification is given as:

```julia
@param begin
    θ ∈ VectorDomain(2; lower=[0.0,0.0], upper=[20.0,20.0])
    Ω ∈ PSDDomain(2)
    Σ ∈ RealDomain(; lower=0.01, upper=0.2)
end
```

Then in `simobs(model, data, param)` or `fit(model, data, param)`, the parameters
`param` must be a `NamedTuple` of values where the type fits in the domain.
For example, `param` must have `param.θ` as a `Vector`. Thus the following
would be a valid definition of `param` for this structure:

```julia
param = (
    θ = [0.4, 7.0],
    Ω = [0.04 0.0
         0.0  0.01],
    Σ = 0.1
    )
```

Below are the specifications of the `Domain` types and their matching value
types.

## RealDomain and VectorDomain

`RealDomain` and `VectorDomain` are the core domain types of Pumas. A `RealDomain`
defines a scalar value which exists in the real line, while a `VectorDomain`
defines a real-valued vector which lives in a hypercube of $$\mathbb{R}^n$$.
The length `n` of a `VectorDomain` is a required positional argument.
Each of these allow keyword arguments for setting an `upper` and `lower` bound
for the segment, where for the `RealDomain` these are scalars and for the
`VectorDomain` it is a vector of upper and lower bound for each component of
the vector. Thus the constructors are:

```julia
RealDomain(; upper, lower)
VectorDomain(n; upper, lower)
```

A `RealDomain` requires that the matching parameters are an `AbstractFloat` type.
A `VectorDomain` requires that the matching parameters are a `Vector` of an
`AbstactFloat` type which has the correct size.

## Positive-Definite Matrix Domains

In many cases, one may wish to specify a positive-definite covariance matrix
as a parameter in a model. A common use case for this functionality is for
defining the domain of a random effect. There are two domains for
positive-definite matrices: `PSDDomain` and `PDiagDomain`. Both of the
constructors require the size `n` of the `n x n` postive-definite matrix:

```julia
PSDDomain(n)
PDiagDomain(n)
```

A `PSDDomain` requires that the matching matrix input is positive definite but
puts no further restrictions on the matrix. If a domain is specified as
`Ω ∈ PSDDomain(2)`, then

```julia
Ω = [0.04 0.0
     0.0  0.01]
```

is a valid parameter specification. The `PDiagDomain` restricts the parameter
space to positive definite diagonal matricesis, i.e. diagonal matrices with positive
diagonal elemenets. Thus, if a domain is specified as `Ω ∈ PDiagDomain(2)`, then

```julia
Ω = Diagonal([0.0, 1.0])
```

is a valid parameter specification.

## Distributional Domains

Instead of using a `Domain` type from Pumas, a `Distribution` can be used to
specify a domain. For example,

```julia
Ω ~ Normal(0,1)
```

is a valid domain specification. If this is done, then the probability
distribution is used and interpreted as the prior distribution. Implicitly,
the domain of a distribution is treated as the support of the distribution.
A distributional domain requires that the matching parameter is of the same
type as a sample from the domain. For example, if `Ω ~ Normal(0,1)`, then `Ω`
should be given as a scalar.

## Constrained

The `Constrained` domain is for defining a `Constrained` probability distribution.
`Constrained` takes in a distribution and has keyword arguments for `upper`
and `lower` bounds. For example, `ψ ~ Constrained(MVNormal(Ω),lower=[0.0,0.0])`
defines a `ψ` to be from the distributional domain which corresponds to a
multivariate normal distribution, but is constrained to be positive. Like
with the distributional domains, `Constrained` requires that the matching
parameter is of the same type as a sample from the domain.

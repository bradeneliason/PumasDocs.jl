# Bioequivalence

Bioequivalence.jl is a package for performing bioequivalence analysis.

The full API is available in the next section and provides the signatures and examples for using all the functionality available.

## Quickstart

In order to use Bioequivalence.jl, add the package through

```julia
using Pkg
Pkg.add("Bioequivalence")
```

or using the package REPL

```julia
]add Bioequivalence
```

You can then load the library through

```@example Main
using Bioequivalence
```

A bioequivalence study is an instance of the type `BioequivalenceStudy` and can be constructed through the `pumas_be` function.

## Designs

There are multiple study designs supported including:

- Nonparametric analysis (i.e., x formulations, y sequences, z periods)

The nonparametric design performs a Wilcoxon signed rank test of the null hypothesis that the distribution of x (or the difference x - y if y is provided) has zero median against the alternative hypothesis that the median is non-zero.

When there are no tied ranks and ≤ 50 samples, or tied ranks and ≤ 15 samples, SignedRankTest performs an exact signed rank test. In all other cases, SignedRankTest performs an approximate signed rank test.

- Parallel design (i.e., x formulations, y sequences, 1 period, e.g. `R|S|T`)

Perform an unequal variance two-sample t-test of the null hypothesis that `x` and `y` come from distributions with equal means against the alternative hypothesis that the distributions have different means.
This test is sometimes known as Welch's t-test. It differs from the equal variance t-test in that it computes the number of degrees of freedom of the test using the Welch-Satterthwaite equation:

```math
    ν_{χ'} ≈ \frac{\left(\sum_{i=1}^n k_i s_i^2\right)^2}{\sum_{i=1}^n
        \frac{(k_i s_i^2)^2}{ν_i}}
```

- Crossover design (i.e., 2 formulations, 2 sequences, 2 periods, e.g., `RT|TR`)

Performs a linear regression with the following model

```math
    \ln\left(endpoint\right) = β₀ + β₁ formulation + β₂ sequence + β₃ period + β₄ id + ε
```
where βⱼ, j ∈ [1, 2, 3, 4], are vectors for features where `formulation` uses the dummy variable coding and `sequence` and `period` use contrast coding.

- Balaam design (i.e., 2 formulations, 4 sequences, 2 periods, e.g., `RR|RT|TR|TT`)
- Dual design (i.e., 2 formulations, 2 sequences, 3 periods, e.g., `RTT|TRR`)
- Inner design (i.e., 2 formulations, 2 sequences, 4 periods, e.g., `RRTT|TTRR`)
- Outer design (i.e., 2 formulations, 2 sequences, 4 periods, e.g., `RTRT|TRTR`)
- Williams 3 Design (i.e., 3 formulations, 6 sequences, 3 periods, e.g., `RST|RTS|SRT|STR|TRS|TSR`)
- Williams 4 Design (i.e., 4 formulations, 4 sequences, 4 periods, e.g., `ADBC|BACD|CBDA|DCAB`)

The designs: *Balaam*, *Dual*, *Inner*, *Outer*, *Williams 3*, and *Williams 4* all use the following linear mixed model

```
log(endpoint) ~ formulation + sequence + period + (1 | id)
```

which is equivalent to 

```
proc mixed data=data method=ml;
class sequence subject period formula;
model ln_endpoint= sequence period formula;
random subject(sequence);
```

in SAS.

!!! tip

    One can request to use the restricted maximum likelihood (REML) objective to match SAS default value through passing the `reml = true` argument to `pumas_be`.

Since the study design can be inferred from the data argument (i.e., based on sequences, formulations, and periods), the inferred study design approach will be automatically selected. Once can manually overwrite the method for the nonparametric option by selecting `nonparametric = true` in `pumas_be`.

Every design supports estimating the average bioequivalence (population). Those study designs that allow for estimating individual bioequivalence (i.e., Balaam, Dual, Inner, Outer) report the estimates for individual population as well.

## Next Steps

Explore the API in the next section as well as the tutorials to learn more about how to use the module.

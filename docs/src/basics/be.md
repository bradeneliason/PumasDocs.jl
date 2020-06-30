# Bioequivalence Analysis (BE)

Bioequivalence.jl is a package for performing bioequivalence analysis.

The full API is available in the next section and provides the signatures and examples for using all the available functionality.

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

### Nonparametric analysis (i.e., x formulations, y sequences, z periods)

The nonparametric design performs a Wilcoxon signed rank test of the null hypothesis that the distribution of the reference formulation and the distribution of an alternative formulation have the same median.

When there are no tied ranks and ≤ 50 samples, or tied ranks and ≤ 15 samples, it will perform an exact signed rank test or approximate it otherwise.

Since the study design can be inferred from the data argument (i.e., based on sequences, formulations, and periods), the inferred study design approach will be automatically selected. Once can manually overwrite the method for the nonparametric option by selecting `nonparametric = true` in `pumas_be`.

### Parallel design (i.e., x formulations, y sequences, 1 period, e.g. `R|S|T`)

Perform a Welch's t-test (i.e., unequal variance two-sample t-test) of the null hypothesis that the distribution of the reference formulation and the distribution of an alternative formulation comes have equal means. The number of degrees of freedom of the test uses the Welch-Satterthwaite equation:

```math
    ν_{χ'} ≈ \frac{\left(\sum_{i=1}^n k_i s_i^2\right)^2}{\sum_{i=1}^n
        \frac{(k_i s_i^2)^2}{ν_i}}
```

### Crossover design (i.e., 2 formulations, 2 sequences, 2 periods, e.g., `RT|TR`)

Performs a linear regression with the following model

```math
    \ln\left(endpoint\right) = β₀ + β₁ formulation + β₂ sequence + β₃ period + β₄ id + ε
```
where βⱼ, j ∈ [1, 2, 3, 4], are vectors for features where `formulation` uses the dummy variable coding and `sequence` and `period` use contrast coding.

### Higher Order

The following linear mixed model

```
log(endpoint) ~ formulation + sequence + period + (1 | id)
```

is used for the following designs:

- Balaam design (i.e., 2 formulations, 4 sequences, 2 periods, e.g., `RR|RT|TR|TT`)
- Dual design (i.e., 2 formulations, 2 sequences, 3 periods, e.g., `RTT|TRR`)
- Inner design (i.e., 2 formulations, 2 sequences, 4 periods, e.g., `RRTT|TTRR`)
- Outer design (i.e., 2 formulations, 2 sequences, 4 periods, e.g., `RTRT|TRTR`)
- Williams 3 Design (i.e., 3 formulations, 6 sequences, 3 periods, e.g., `RST|RTS|SRT|STR|TRS|TSR`)
- Williams 4 Design (i.e., 4 formulations, 4 sequences, 4 periods, e.g., `ADBC|BACD|CBDA|DCAB`)

!!! info
    
    The linear mixed model corresponds to
    
    ```
    proc mixed data = data method = ml;
    class sequence subject period formula;
    model ln_endpoint = sequence period formula;
    random subject(sequence);
    ```
    
    in SAS.

!!! tip

    One can request to use the restricted maximum likelihood (REML) objective to match SAS default value through passing the `reml = true` argument to `pumas_be`.

!!! note

    Every design supports estimating the average bioequivalence (population).
    
    Those study designs that allow for estimating individual bioequivalence (i.e., Balaam, Dual, Inner, Outer) report the estimates for individual population as well.

!!! validation

    Each design has been tested using various sources including:

    - Chow, Shein-Chung, and Jen-pei Liu. 2009. Design and Analysis of Bioavailability and Bioequivalence Studies. 3rd ed. Chapman & Hall/CRC Biostatistics Series 27. Boca Raton: CRC Press. DOI: [10.1201/9781420011678](https://doi.org/10.1208/s12248-014-9704-6).
    - Fuglsang, Anders, Helmut Schütz, and Detlew Labes. 2015. "Reference Datasets for Bioequivalence Trials in a Two-Group Parallel Design." The AAPS Journal 17 (2): 400–404. DOI: [10.1208/s12248-014-9704-6](https://doi.org/10.1208/s12248-014-9704-6).
    - Patterson, Scott D, and Byron Jones. 2017. Bioequivalence and Statistics in Clinical Pharmacology. 2nd ed. Chapman & Hall/CRC Biostatistics Series. DOI: [10.1201/9781315374161](https://dx.doi.org/10.1201/9781315374161).
    - Schütz, Helmut, Detlew Labes, and Anders Fuglsang. 2014. "Reference Datasets for 2-Treatment, 2-Sequence, 2-Period Bioequivalence Studies." The AAPS Journal 16 (6): 1292–97. DOI: [10.1208/s12248-014-9661-0](https://doi.org/10.1208/s12248-014-9661-0).

## API

### Public

```@autodocs
Modules = [Bioequivalence]
Private = false
```

### Private

```@autodocs
Modules = [Bioequivalence]
Public = false
```

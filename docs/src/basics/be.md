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

## What is bioequivalence?

Bioequivalence is a concept in pharmacokinetics that captures the idea that various pharmaceutical products administrated in a similar manner (e.g., same molar dose of the same active ingredient, route of administration) can be expected to have, for all intents and purposes, the same effect on individuals in a defined population.

Clinical studies collect data which can be analyzed such as through noncompartmental analysis to obtain insightful descriptives about the contentration curve also known as pharmacokinetic endpoints. These endpoints relate to the rate (e.g., maximum concentration, time of peak concentration) and extent of absorption (e.g., area under the curve). Bioequivalence relies on the study design and pharmacokinetic endpoints from clinical trials or simulation models to make a determination about the expected effects of formulations.

Three major types of bioequivalence are regularly used:

1. Average (ABE): are the mean values of the distributions of the pharmacokinetic endpoints for the reference and the test formulations similar enough? The concept is the most popular with a rise in adoption in the early 1990's by the United States and the European Union. It is considered to be the easiest criterion for a new formulation to achieve bioequivalence. It is required by most regulatories agencies for the product to be approved under a bioequivalence process.

2. Population (PBE): are the distributions of the pharmacokinetic endpoints for the reference and the test formulations similar enough? In this case, it is not longer comparing just the expected value of the distributions but the full distribution. PBE is especially important for determining prescribability or the decision to assign a patient one of formulations as part of a treatment for the first time.

3. Individual (IBE): are the distributions of the pharmacokinetic endpoints for the reference and the test formulations similar enough across a large proportion of the intended population? IBE is particularly relevant for switchability or the decision to substitute an ongoing regimen (change formulation) without detrimental effects to the patient.

PBE and IBE can be assessed through two different methods:

1. constant scaling: the regulatory agency provides a value to be used in determining PBE or IBE.

2. reference scaling: the estimated total variance of the reference formulation in determining PBE or IBE.

3. mixed scaling: use reference scaling when the estimated total variance of the reference formulation is greater than that of the test formulation and the constant scaling otherwise.

!!! note

    One argument for using the mixed scaling is that if the estimate of the total variance of the test formulation is greater than of the reference it bioequivalence would be very conservative.

!!! info

    The reference scaling system is most used when working with highly variable drugs (HVD), those with intrasubject variability > 30%, and narrow therapeutic index drugs (NTI), those drugs where small differences in dose or blood concentration may lead to serious therapeutic failures and/or adverse drug reactions that are life-threatening or result in persistent or significant disability or incapacity.

## Designs

There are three major categories of bioequivalence study desings.

Nonparametric for endpoints such as time of maximum concentration which typically do not have (or can easily transformed) a normal-like distribution.

Parallel designs which are typically used when crossover designs are not feasible.

Crossover (replicated and nonreplicated) designs which are the most commonly used by the industry.

Designs are fully characterized by:

- Subjects: participants in the study (each is assigned to a sequence)
- Formulations: the different formulations being compared (i.e., reference and additional test formulations)
- Periods: each dosing period at which each subject is administrated a formulation based on the sequence it has been assigned to
- Sequences: a dosing regimen which establishes what formulation is given at each period

!!! warning

    The periods should be spaced enough such that there are no carryover effects from dosings in the previous periods.

### Nonparametric analysis (i.e., x formulations, y sequences, z periods)

The nonparametric design performs a Wilcoxon signed rank test of the null hypothesis that the distribution of the reference formulation and the distribution of an alternative formulation have the same median.

When there are no tied ranks and ≤ 50 samples, or tied ranks and ≤ 15 samples, it will perform an exact signed rank test or approximate it otherwise.

Since the study design can be inferred from the data argument (i.e., based on sequences, formulations, and periods), the inferred study design approach will be automatically selected. Once can manually overwrite the method for the nonparametric option by selecting `nonparametric = true` in `pumas_be`.

### Parallel design (i.e., x formulations, y periods, z sequences, e.g. `R|S|T`)

Perform a Welch's t-test (i.e., unequal variance two-sample t-test) of the null hypothesis that the distribution of the reference formulation and the distribution of an alternative formulation comes have equal means. The number of degrees of freedom of the test uses the Welch-Satterthwaite equation:

```math
    ν_{χ'} ≈ \frac{\left(\sum_{i=1}^n k_i s_i^2\right)^2}{\sum_{i=1}^n
        \frac{(k_i s_i^2)^2}{ν_i}}
```

### Crossover designs

Crossover designs are divided into two categories:

1. Replicated

2. Nonreplicated

Nonreplicated designs have subjects assigned to distinct formulations in each period.

Replicated crossover designs are those with subjects receiving the same formulation more than once.
A key feature of replicated designs is that it allows to estimate within-subject variances per formulation which are a component for assessing PBE and IPE.

Common crossover designs:

|    Name    | Number of Formulations | Number of Periods | Number of Sequences |            Example           | Replicated |
|:----------:|:----------------------:|:-----------------:|:-------------------:|:----------------------------:|:----------:|
|     2x2    |            2           |         2         |          2          |            RT\|TR            |    false   |
|   Balaam   |            2           |         2         |          2          |        RR\|RT\|TR\|TT        |    true    |
|    Dual    |            2           |         3         |          2          |           RTT\|TRR           |    true    |
|    Inner   |            2           |         4         |          2          |          RRTT\|TTRR          |    true    |
|    Outer   |            2           |         4         |          2          |          RTRT\|TRTR          |    true    |
| Williams 3 |            3           |         3         |          6          | RST\|RTS\|SRT\|STR\|TRS\|TSR |    false   |
| Williams 4 |            4           |         4         |          4          |    ADBC\|BACD\|CBDA\|DCAB    |    false   |

Replicated designs are preferred, particularly the inner and outer designs.

If employing the dual design, it is recommended to have a larger sample size in order to achieve the same level of statistical power.

!!! note

    In the United States, there is a minimum requirement of at least 12 evaluable subjects for any bioequivalence study.

For analyzing more than two formulations at a time, the Williams designs, a generalized latin square, is the preferred design given its statistical power.

There are two ways to analyze crossover designs:

#### Linear model

Performs a linear regression with the following model

```math
    \ln\left(endpoint\right) = β₀ + β₁ formulation + β₂ sequence + β₃ period + β₄ id + ε
```
where βⱼ, j ∈ [1, 2, 3, 4], are vectors for features where `formulation` uses the dummy variable coding and `sequence` and `period` use contrast coding.

#### Linear mixed model

```
log(endpoint) ~ formulation + sequence + period + (1 | id)
```

!!! info
    
    The linear mixed model corresponds to
    
    ```
    proc mixed data = data method = ml;
    class sequence subject period formulation;
    model ln_endpoint = sequence period formulation;
    random subject(sequence);
    ```
    
    in SAS.

!!! tip

    One can request to use the restricted maximum likelihood (REML) objective to match SAS default value through passing the `reml = true` argument to `pumas_be`.

!!! tip

    Per the Food and Drug Administration (US regulatory agency) [guidance](https://ntrl.ntis.gov/NTRL/dashboard/searchResults/titleDetail/PB2010104191.xhtml), replicated crossover designs should employ the linear mixed model approach while nonreplicated crossover desings should employ a linear model (linear mixed models for nonreplicated crossover desings are also acceptable).

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

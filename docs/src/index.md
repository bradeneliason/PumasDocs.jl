# Pumas

Pumas (PharmaceUtical  Modeling And Simulation) is a suite of tools to perform quantitative
analytics of various kinds across the horizontal of pharmaceutical drug development. The
purpose of this framework is to bring efficient implementations of all aspects of the analytics
in this domain under one cohesive package. Pumas 1.0 currently includes:

- Non-compartmental Analysis
- Specification of Nonlinear Mixed Effects (NLME) Models
- Simulation of NLME model using differential equations or analytical solutions
- Deep control over the differential equation solvers for high efficiency
- Estimation of NLME parameters via Maximum Likelihood and Bayesian methods
- Parallelization capabilities for both simulation and estimation
- Mixed analytical and numerical problems
- Interfacing with global optimizers for more accurate parameter estimates
- Simulation and estimation diagnostics for model post-processing
- Global and local sensitivity analysis routines for multi-scale models
- Bioequivalence analysis

Additional features are under development, with the central goal being a
complete clinical trial simulation engine which combines efficiency with a
standardized workflow, consistent nomenclature, and automated report generation.
All of this takes place in the high level interactive Julia programming language
and integrates with the other packages in the Julia ecosystem for a robust
user experience.

## License

Pumas is covered by the [Julia Computing EULA](https://juliacomputing.com/eula).
Pumas is a proprietary product developed by Pumas-AI, Inc. It is available free of cost
for educational and research institutes. For commercial use, please contact sales@pumas.ai

## Getting Started: Installation and First Steps

Pumas can be downloaded from https://pumas.ai/products/pumas/download

One can start using Pumas by invoking it from the REPL as below.

```julia
using Pumas
```

To start understanding the package in more detail, please checkout the tutorials
at the start of this manual. **We highly suggest that all new users start with
the Introduction to Pumas tutorial!** If you find any example where there seems
to be an error, please open an issue.

If you have questions about usage, please join the official [Pumas Discourse](https://discourse.pumas.ai/) and take part in the discussion there. There is also a #pumas channel on the [JuliaLang Slack](https://julialang.slack.com/) for more informal discussions around Pumas.jl usage.

## Annotated Table Of Contents

Below is an annotated table of contents with summaries to help guide you to the
appropriate page. The materials shown here are links to the same materials
in the sidebar. Additionally, you may use the search bar provided on the left
to directly find the manual pages with the appropriate terms.

### Tutorials

These tutorials give an "example first" approach to learning Pumas and establish
the standardized nomenclature for the package. Additionally, ways of interfacing
with the rest of the Julia ecosystem for visualization and statistics are
demonstrated. Thus we highly recommend new users check out these tutorials
before continuing into the manual. More tutorials can be found at https://tutorials.pumas.ai/

```@contents
Pages = [
    "tutorials/introduction.md",
]
```

### Basics

The basics are the core principles of using Pumas. An overview introduces the
user to the basic design tenants, and manual pages proceed to give details on
the central functions and types used throughout Pumas.

```@contents
Pages = [
    "basics/overview.md",
    "basics/models.md",
    "basics/doses_subjects_populations.md",
    "basics/simulation.md",
    "basics/estimation.md",
    "basics/nca.md",
    "basics/be.md",
    "basics/faq.md",
]
```

### Model Components

This section of the documentation goes into more detail on the model components,
specifying the possible domain types, dosage control parameters (DCP), and
the various differential equation types for specifying problems with
analytical solutions and alternative differential equations such as delay
differential equations (DDEs), stochastic differential equations (SDEs), etc.

```@contents
Pages = [
    "model_components/domains.md",
    "model_components/dosing_control.md",
    "model_components/dynamical_types.md",
]
```

### Analysis

This section of the documentation defines the analysis tooling. Essential
tools such as diagnostics, plotting, report generation, and sensitivity
analysis are discussed in detail in this portion.

```@contents
Pages = [
    "analysis/diagnostics.md",
]
```

## Pumas Development Team

Please visit https://pumas.ai/ to know more about our team and capabilities

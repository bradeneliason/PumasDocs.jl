# Visual Predictive Check (VPC)

Pumas allows you to generate VPC quantiles for your data and model simulations
and utilize the Julia plotting capabilities to generate the relevant VPC plots.
This is allowed with the `vpc` function discuseed below that returns a `VPC` object.

```julia
 vpc(fpm::FittedPumasModel,
                reps::Integer = 499,
                qreg_method = IP(),
                vpctype::VPCType = ContinuousVPC();
                dv::Symbol = keys(fpm.data[1].observations)[1],
                stratify_by = nothing,
                quantiles::NTuple{3,Float64}=(0.1, 0.5, 0.9),
                level::Real=0.95,
                ensemblealg=EnsembleSerial(),
                bandwidth=2,
                numstrats=stratify_by === nothing ? nothing : [4 for i in 1:length(stratify_by)])
```
`vpc` computes the quantiles for VPC for a `FittedPumasModel` with simulated prediction intervals 
around the empirical quantiles based on `reps`simulated populations.

 The following keyword arguments are supported:
    - `quantiles::NTuple{3,Float64}`: A three-tuple of the quantiles for which the quantiles will be computed. The default is `(0.1, 0.5, 0.9)` which computes the
                                                                        10th, 50th and 90th percentile.
    - `level::Real`: Probability level to use for the simulated prediction intervals. The default is `0.95`.
    - `dv::Symbol`: The name of the dependent variable to use for the VPCs. The default is the first dependent variable in the dataset.
    - `stratify_by`: The covariates to be used for stratification. Takes an array of the `Symbol`s of the stratification covariates.
    - `ensemblealg`: This is passed to the `simobs` call while the `reps` simulations. For more description check the docs for `simobs`.
    - `bandwidth`: The kernel bandwidth in the quantile regression. If you are seeing `NaN`s or an error, increasing the bandwidth should help in most cases.
                                With higher values of the `bandwidth` you will get more smoothened plots of the quantiles so it's a good idea to check with your data the right `bandwidth`.
    - `numstrats`: The number of strata to divide into based on the unique values of the covariate, takes an array with the number of strata for the corresponding covariate
                                passed in `stratify_by`. It takes a default of `4` for each of the covariates.

For most users the method used in quantile regression is not going to be of concern, but if you see large run times switching `qreg_method` to `IP(true)` should help in improving the
performance with a tradeoff in the accuracy of the fitting.

While plotting the obtained `VPC` object with `plot` the following keyword arguments allow the option to include or exclude various components with `true` or `false` respectively:

    - `observations`: Scatter plot of the true observations.
    - `simquantile_medians`: The median quantile regression of each quantile from the simulations.
    - `observed_quantiles`: The quantile regressions for the true observations.
    - `ci_bands`: Shaded region between the upper and lower confidence levels of each quantile from the simulations.

    `observations` and `simquantile_medians` are set to `false` by default.


Examples: 

```julia
model = @model begin
            @param     begin
                tvcl ∈ RealDomain(lower=0)
                tvv ∈ RealDomain(lower=0)
                pmoncl ∈ RealDomain(lower = -0.99)
                Ω ∈ PDiagDomain(2)
                σ_prop ∈ RealDomain(lower=0)
            end

            @random begin
                η ~ MvNormal(Ω)
            end

            @covariates wt isPM

            @pre begin
                CL = tvcl * (1 + pmoncl*isPM) * (wt/70)^0.75 * exp(η[1])
                Vc    = tvv * (wt/70) * exp(η[2])
            end

            @dynamics Central1
                #@dynamics begin
                #        Central' =    - (CL/V)*Central
                #end

            @derived begin
                    cp = @. 1000*(Central / Vc)
                    dv ~ @. Normal(cp, sqrt(cp^2*σ_prop))
            end
    end

    ev = DosageRegimen(100, time=0, addl=2, ii=24)
    s1 = Subject(id=1, events=ev, covariates=(isPM=1, wt=70))

    param = (
        tvcl = 4.0,
        tvv    = 70,
        pmoncl = -0.7,
        Ω = Diagonal([0.09,0.09]),
        σ_prop = 0.04
        )

    choose_covariates() = (isPM = rand([1, 0]),
    wt = rand(55:80))
    pop_with_covariates = Population(map(i -> Subject(id=i, events=ev, covariates=choose_covariates()),1:10))
    obs = simobs(model, pop_with_covariates, param, obstimes=0:1:60)
    simdf = DataFrame(obs)
    simdf[rand(1:length(simdf.dv), 5), :dv] .= missing
    data = read_pumas(simdf, time=:time, covariates=[:isPM, :wt])

    vpc_data = vpc(data)
    vpc_data_stratwt = vpc(data, stratify_by=[:wt])

    vpc_model = vpc(model, data, param, 100)
    vpc_model_stratwt = vpc(model, data, param, 100, stratify_by=[:wt])

    res = fit(model,data,param,Pumas.FOCEI())
    vpc_fpm = vpc(res, 100)
    vpc_fpm_stratispm = vpc(res, 100, stratify_by=[:isPM])
```

```julia

  data = read_pumas(joinpath(dirname(pathof(Pumas)), "..", "examples", "pain_remed.csv"),
    covariates = [:arm, :dose, :conc, :painord];
    time=:time, event_data=false)

  model = @model begin
    @param begin
      θ₁ ∈ RealDomain(init=0.001)
      θ₂ ∈ RealDomain(init=0.0001)
      Ω  ∈ PSDDomain(1)
    end

    @random begin
      η ~ MvNormal(Ω)
    end

    @covariates arm dose

    @pre begin
      rx = dose > 0 ? 1 : 0
      LOGIT = θ₁ + θ₂*rx + η[1]
    end

    @derived begin
      dv ~ @. Bernoulli(logistic(LOGIT))
    end

  end

  param = (θ₁=0.01, θ₂=0.001, Ω=fill(1.0, 1, 1))

  vpc_data = vpc(data, IP(), Pumas.DiscreteVPC(), idv = :dose)
  @test typeof(vpc_data) <: Pumas.PopVPC

  vpc_model = vpc(model, data, param, 100, IP(), Pumas.DiscreteVPC(), idv = :dose)
  @test typeof(vpc_model) <: Pumas.VPC

  res = fit(model,data,param,Pumas.FOCE())
  vpc_fpm = vpc(res, 100, IP(), Pumas.DiscreteVPC(), idv = :dose)
```


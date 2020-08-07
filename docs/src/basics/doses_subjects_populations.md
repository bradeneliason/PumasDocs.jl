# Dosage Regimens, Subjects, and Populations
```@meta
DocTestSetup = quote
using Pumas
end
```
In Pumas, subjects are represented by the `Subject` type and collections of
subjects are represented as `Vector`s of `Subject`s aliased `Population`. Subjects
are defined by their identifier, observations, covariates, and events. In this
section we will specify the methods used for defining `Subject`s programmatically
or using the `read_pumas` function that reads in data that follows the Pumas NLME Data Format
(PumasNDF) data format. Before we look at `Subject`s, we will take a look at how to define events
as represented by the `DosageRegimen` type.

## Dosage Regimen Terminology

When subjects are subjected to treatment it is represented by an _event_ in Pumas.
Administration of a drug is represented by a `DosageRegimen` that describes the
amount, type, frequency and route. `DosageRegimen`s can either be constructed
programmatically using the `DosageRegimen` constructor or from a data source in
the `PumasNDF` format using `read_pumas`. The names of the inputs are the same
independent of how the `DosageRegimen` is constructed. The definition of the values are as follows:

- `amt`: the amount of the dose. This is the only required value.
- `time`: the time at which the dose is given. Defaults to 0.
#TODO - check `evid` details below
- `evid`: the event id. `1` specifies a normal event. `3` means it's a reset event,
  meaning that the value of the dynamical variable is reset to the `amt` at the
  dosing event. If `4`, then the value is reset (to the steady state), and then
  a final dose is given. Defaults to `1`.
- `ii`: the interdose interval. For steady state events, this is the length of
  time between successive doses. When `addl` is specified, this is the length
  of time to the next dose. Defaults to `0`.
- `addl`: the number of additional events of the same types, spaced by `ii`.
  Defaults to 0.
- `rate`: the rate of administration. If `0`, then the dose is instantaneous.
  Otherwise the dose is administrated at a constant rate for a duration equal
  to `amt/rate`.
- `ss`: an indicator for whether the dose is a steady state dose. A steady state
  dose is defined as the result of having applied the dose with the interval `ii`
  infinitely many successive times. `0` indicates that the dose is not a steady
  state dose. 1 indicates that the dose is a steady state dose. 2 indicates that
  it is a steady state dose that is added to the previous amount. The default
  is 0.

This specification leads to the following default constructor for the `DosageRegimen` type

```julia
DosageRegimen(amt::Numeric;
              time::Numeric = 0,
              cmt::Union{Numeric,Symbol} = 1,
              evid::Numeric = 1,
              ii::Numeric = zero.(time),
              addl::Numeric = 0,
              rate::Numeric = zero.(amt)./oneunit.(time),
              duration::Numeric = zero(amt)./oneunit.(time),
              ss::Numeric = 0)
```

Each of the values can either be or scalars. All vectors must
be of the same length, and the elementwise combinations each define an event
(with scalars being repeated).

A `DosageRegimen` can be converted to its tabular form using the
`DataFrame` function: `DataFrame(dr)`.

Let us try to construct a few dosage regimens to see how these inputs change
the constructed `DosageRegimen`s. First, a simple instantaneous (default) dose
with the amount `9`:

```jldoctest
DosageRegimen(9)

# output

DosageRegimen
│ Row │ time    │ cmt   │ amt     │ evid │ ii      │ addl  │ rate    │ duration │ ss   │
│     │ Float64 │ Int64 │ Float64 │ Int8 │ Float64 │ Int64 │ Float64 │ Float64  │ Int8 │
├─────┼─────────┼───────┼─────────┼──────┼─────────┼───────┼─────────┼──────────┼──────┤
│ 1   │ 0.0     │ 1     │ 9.0     │ 1    │ 0.0     │ 0     │ 0.0     │ 0.0      │ 0    │
```

We see that the default compartments, rates, etc were set for us. We recommend always setting
a compartment name or index, so let us do that, and change the dosage regimen to a constant rate
of 0.1. This implies a duration of 90:

```jldoctest
DosageRegimen(9.0; cmt=:Central, rate=0.1)

# output

DosageRegimen
│ Row │ time    │ cmt     │ amt     │ evid │ ii      │ addl  │ rate    │ duration │ ss   │
│     │ Float64 │ Symbol  │ Float64 │ Int8 │ Float64 │ Int64 │ Float64 │ Float64  │ Int8 │
├─────┼─────────┼─────────┼─────────┼──────┼─────────┼───────┼─────────┼──────────┼──────┤
│ 1   │ 0.0     │ Central │ 9.0     │ 1    │ 0.0     │ 0     │ 0.1     │ 90.0     │ 0    │
```

We can also construct a dosage regimen that is composed of several `DosageRegimen`s, this is
done by passing several `DosageRegimen` instances to the `DosageRegimen` constructor:

```jldoctest
dr1 = DosageRegimen(9.0; cmt=:Central, rate=0.1)
dr2 = DosageRegimen(9.0; time=1.0, cmt=:Central, rate=0.1)

DosageRegimen(dr1, dr2)

# output

DosageRegimen
│ Row │ time    │ cmt     │ amt     │ evid │ ii      │ addl  │ rate    │ duration │ ss   │
│     │ Float64 │ Symbol  │ Float64 │ Int8 │ Float64 │ Int64 │ Float64 │ Float64  │ Int8 │
├─────┼─────────┼─────────┼─────────┼──────┼─────────┼───────┼─────────┼──────────┼──────┤
│ 1   │ 0.0     │ Central │ 9.0     │ 1    │ 0.0     │ 0     │ 0.1     │ 90.0     │ 0    │
│ 2   │ 1.0     │ Central │ 9.0     │ 1    │ 0.0     │ 0     │ 0.1     │ 90.0     │ 0    │
```

In this case, the second dose was simply a repetition of the first after 1 unit of time. In
this instance, we could also have used `dr1` together with the `offset` keyword to `DosageRegimen`:

```jldoctest
DosageRegimen(dr1, dr1, offset = 1.0)

# output

DosageRegimen
│ Row │ time    │ cmt     │ amt     │ evid │ ii      │ addl  │ rate    │ duration │ ss   │
│     │ Float64 │ Symbol  │ Float64 │ Int8 │ Float64 │ Int64 │ Float64 │ Float64  │ Int8 │
├─────┼─────────┼─────────┼─────────┼──────┼─────────┼───────┼─────────┼──────────┼──────┤
│ 1   │ 0.0     │ Central │ 9.0     │ 1    │ 0.0     │ 0     │ 0.1     │ 90.0     │ 0    │
│ 2   │ 1.0     │ Central │ 9.0     │ 1    │ 0.0     │ 0     │ 0.1     │ 90.0     │ 0    │
```

We could also have used the `ii` and `addl` keywords to construct a more compact representation of the same
dosage regimen:

```jldoctest
DosageRegimen(9.0; cmt=:Central, rate=0.1, addl=1, ii=1.0)

# output

DosageRegimen
│ Row │ time    │ cmt     │ amt     │ evid │ ii      │ addl  │ rate    │ duration │ ss   │
│     │ Float64 │ Symbol  │ Float64 │ Int8 │ Float64 │ Int64 │ Float64 │ Float64  │ Int8 │
├─────┼─────────┼─────────┼─────────┼──────┼─────────┼───────┼─────────┼──────────┼──────┤
│ 1   │ 0.0     │ Central │ 9.0     │ 1    │ 1.0     │ 1     │ 0.1     │ 90.0     │ 0    │
```

Finally, we show the vector form mentioned above. If we input vectors instead of scalars, we
can simultaneously define several administrations in one constructor as follows:

```jldoctest
DosageRegimen([9.0, 18]; cmt=:Central, rate=[0.1, 1.0], time=[1.0, 5.0], addl=1, ii=2)

# output

DosageRegimen
│ Row │ time    │ cmt     │ amt     │ evid │ ii      │ addl  │ rate    │ duration │ ss   │
│     │ Float64 │ Symbol  │ Float64 │ Int8 │ Float64 │ Int64 │ Float64 │ Float64  │ Int8 │
├─────┼─────────┼─────────┼─────────┼──────┼─────────┼───────┼─────────┼──────────┼──────┤
│ 1   │ 1.0     │ Central │ 9.0     │ 1    │ 2.0     │ 1     │ 0.1     │ 90.0     │ 0    │
│ 2   │ 5.0     │ Central │ 18.0    │ 1    │ 2.0     │ 1     │ 1.0     │ 18.0     │ 0    │
```

## The `Subject` Constructor

The dosage regimens only a subset of what we need to fully specify a subject. As mentioned above, we use the `Subject` type to represent individuals in Pumas. The can be constructed using the `Subject` constructor programatically or using `read_pumas` from tabular data. The constructor has the following keywords and default values:

```julia
Subject(;id = "1",
         observations = nothing,
         events = Pumas.Event[],
         time = observations isa AbstractDataFrame ? observations.time : nothing,
         event_data = true,
         covariates::Union{Nothing, NamedTuple} = nothing,
         covariates_time = observations isa AbstractDataFrame ? observations.time : nothing,
         covariates_direction = :right)
```

The definitions of the arguments are as follows:

- `id` is the id of the subject. Defaults to `"1"` and can be a n`Number` or `String`.
- `observations` holds the observational data. When using the `@model` interface, this must be a `NamedTuple` whose names match those
  of the derived variables.
- `events` is a `DosageRegimen` or a `Vector{<:Pumas.Event}`. Defaults to an empty event list.
- `time` is the time when `observations` are measured
- `event_data` is a boolean which defaults to `true` and triggers that the specified events adhere to the PumasNDF(@ref). When set to `false`, the checks for `PumasNDF` are turned off.
- `covariates` are the covariates for the subject given as a `NamedTuple` of covariate name and value pairs. Defaults to `nothing`, meaning no covariates.
- `covariates_time` - is a `Vector` of times that the `covariates` are observed at or, if some covariates are observed at other times than other covariates, a `NamedTuple` with observation time and covariate name pairs.
- `covariates_direction` - a symbol that determines end-point handling in the piece-wise constant interpolation for time-varying covariates. Allowed values are `:left` and `:right`.

### Constructing `Subject`s

Let's create a few `Subject`s to get the general idea of how to work programatically with subjects in Pumas. We can start with the simplest subject:

```jldoctest
Subject()

# output

Subject
  ID: 1
  Events: 0
```

Suppose we want to construct a Subject with a custom identifier, some observed glucose levels and weight, we can construct the subjects in the following way:

```jldoctest
Subject(;
  id="AKJ491",
  events=DosageRegimen(1.0; time=1.0),
  observations=(glucose=[8.31, 7.709, 5.19],),
  time=[0.3, 0.9, 3.0],
  covariates=(bloodpressure=[(143,95.01), (141.3, 94.8), (130.4, 85.1)],),
  covariates_time=[0.0,0.5, 5.0])

# output

Subject
  ID: AKJ491
  Events: 1
  Observables: glucose: (n=3)
  Covariates: bloodpressure
```

### Reading `Subject`s from tabular data

The `read_pumas` function allows you to read in 

```julia
read_pumas(data; covariates=Symbol[], observations=Symbol[:dv];
                 id=:id, time=:time, evid=:evid, amt=:amt, addl=:addl,
                 ii=:ii, cmt=:cmt, rate=:rate, ss=:ss,
                 event_data=true, covariates_direction=:right,
                 parse_tad = true, check=event_data)
```

The only required argument is `data`. It is the tabular data source given as an actual table (for example using [DataFrame](http://juliadata.github.io/DataFrames.jl/stable/)) or a string that contains the path to something that can be parsed by [CSV.jl](https://github.com/JuliaData/CSV.jl).

The other arguments are optional (keyword arguments) and allow changing the column names from their
default. The keywords `id`, `time`, `covariates`, and `observations` are used to tell what columns to parse
as what type of information and `covariates_direction` is used as in the `Subject` constructor. The keywords
`evid`, `time`, `amt`, `cmt`, `addl`, `ii`, `rate`, `ss`, and `event_data` tells what columns to use for the different
types of information we saw when we constructed `DosageRegimen`s above. The keyword `parse_tad` detects and parses time-after-dose
time in the `time` column, and `check` is used to turn off the data checks mentioned below.

## PumasNDF

The PumasNDF is a specification for building a `Population` from
tabular data. Generally this tabular data is given by a database like a CSV.
The CSV has columns described as follows:

- `id`: the ID of the individual. Each individual should have a unique integer,
  or string.
- `time`: the time corresponding to the row. Should be unique per id, i.e. no
  duplicate time values for a given subject.
- `evid`: the event id. `1` specifies a normal event. `3` means it's a reset event,
  meaning that the value of the dynamical variable is reset to the `amt` at the
  dosing event. If `4`, then the value is reset (to the steady state), and then
  a final dose is given. Defaults to `0` if amt is `0` or missing, and 1 otherwise.
- `amt`: the amount of the dose. If the `evid` column exists and is non-zero,
  this value should be non-zero. Defaults to `0`.
- `ii`: the interdose interval. When `addl` is specified, this is the length
  of time to the next dose. For steady state events, this is the length of
  time between successive doses. Defaults to `0`, and is required to be non-zero on
  rows where a steady-state event is specified.
- `addl`: the number of additional doses of the same time to give. Defaults to 0.
- `rate`: the rate of administration. If `0`, then the dose is instantaneous.
  Otherwise the dose is administrated at a constant rate for a duration equal
  to `amt/rate`. A `rate=-2` allows the `rate` to be determined by a
  [Dosing Control Parameters (DCP)](@ref). Defaults to `0`.
- `ss`: an indicator for whether the dose is a steady state dose. A steady state
  dose is defined as the result of having applied the dose with the interval `ii`
  infinitely many successive times. `0` indicates that the dose is not a steady
  state dose. `1` indicates that the dose is a steady state dose. `2` indicates that
  it is a steady state dose that is added to the previous amount. The default
  is `0`.
- `cmt`: the compartment being dosed. Defaults to `1`.
- `duration`: the duration of administration. If `0`, then the dose is instantaneous.
  Otherwise the dose is administered at a constant rate equal to `amt/duration`.
  Defaults to `0`.
- Observation and covariate columns should be given as a time series of values
  of matching type. Constant covariates should be constant through the full
  column. Time points without a measurement should be denoted by a `.`.

If a column does not exists, its values are imputed to be the defaults.
Special notes:

- If `rate` and `duration` exist, then it is enforced that `amt=rate*duration`
- All values and header names are interpreted as lower case.

### PumasNDF Checks
The `read_pumas` function does some general checks on the provided data and informs the user about inconsistency in the data and throws an error in case of invalid data reporting row number and column name causing the problem so that the user can look and resolve the issue.


Following is the list of checks applied by `read_pumas` function with examples.

1. Necessary columns in case of event and non-event data

   when the `event_data` is `true`, the dataset must contain `id, time, amt, and observations` columns.

   In case of `event_data = false`, only requirement is  `id`.

   ```jldoctest
   df = DataFrame(id=[1,1], time=[0,1], cmt=[1,2], dv=[missing,8],
                   	age=[45,45], sex = ["M","M"], evid=[1,0])
   read_pumas(df, observations=[:dv], covariates=[:age, :sex], event_data=true)

   # output

   ┌ Info: The CSV file has keys: [:id, :time, :cmt, :dv, :age, :sex, :evid]
   └ @ Pumas /home/user/.julia/dev/Pumas/src/data_parsing/io.jl:1023
   PumasDataError: The CSV file must have: `id, time, amt, and observations` when `event_data` is `true`
   ```



2. No `evid` column but `event_data` argument is set to `true`

   When provided dataset doesn't have `evid` column but `event_data=true` is passed to `read_pumas` function.

   ```jldoctest
   df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], cmt=[1,2], dv=[missing,8],
                   	age=[45,45], sex = ["M","M"])
   read_pumas(df, observations=[:dv], covariates=[:age, :sex], event_data=true)

   # output

   ┌ Warning: Your dataset has dose event but it hasn't an evid column. We are adding 1 for dosing rows and 0 for others in evid column. If this is not the case, please add your evid column.
   ```



3. Non-numeric/string entries in an observation column

   If there are non-numeric or string entries in an observation column, `read_pumas` throws an error and reports row(s) and column(s) having this issue.

   ```jldoctest
   df = DataFrame(id=[1,1], time=[0,1], amt=[10,0],
       				cmt=[1,2], dv=[missing,"k@"],
                   	age=[45,45], sex = ["M","M"], evid=[1,0])
   read_pumas(df, observations=[:dv], covariates=[:age, :sex])

   # output

   ERROR: PumasDataError: [Subject id: [1], row = [2], col = dv]  We expect the dv column to be of numeric type.
   These are the unique non-numeric values present in the column dv: ("k@",)
   ```



4. Non-numeric/string entries in `amt` column


   This check is similar to above.

   ```jldoctest
   df = DataFrame(id=[1,1], time=[0,1], amt=["k8",0],
       				cmt=[1,2], dv=[missing,8],
                   	age=[45,45], sex = ["M","M"], evid=[1,0])
   read_pumas(df, observations=[:dv], covariates=[:age, :sex])

   # output

   ERROR: PumasDataError: [Subject id: [1], row = [1], col = amt]  We expect the amt column to be of numeric type.
   These are the unique non-numeric values present in the column amt: ("k8",)
   ```



5. `cmt` must be a positive integer or valid string/symbol for non-zero `evid` data record

   `cmt` column should contain positive numbers or string/symbol identifiers to compartment being dosed.

   ```jldoctest
   df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], cmt=[-1,2], dv=[missing,8],
                   	age=[45,45], sex = ["M","M"], evid=[1,0])
   read_pumas(df, observations=[:dv], covariates=[:age, :sex])

   # output

   ERROR: PumasDataError: [Subject id: 1, row = 1, col = cmt] cmt column should be positive
   ```



6. `amt` can only be `missing` or zero when `evid = 0`

   ```jldoctest
   df = DataFrame(id=[1,1], time=[0,1], amt=[10,5], cmt=[1,2], dv=[missing,8],
                   	age=[45,45], sex = ["M","M"], evid=[1,0])
   read_pumas(df, observations=[:dv], covariates=[:age, :sex])

   # output

   ERROR: umasDataError: [Subject id: 1, row = 2, col = evid] amt can only be missing or zero when evid is zero
   ```



7. `amt` can only be positive or zero when `evid = 1`

   ```jldoctest
   df = DataFrame(id=[1,1], time=[0,1], amt=[-10,0],
       				cmt=[1,2], evid=[1,0], dv=[10,8],
                   	age=[45,45], sex = ["M","M"])
   read_pumas(df, observations=[:dv], covariates=[:age, :sex])

   # output

   ERROR: PumasDataError: [Subject id: 1, row = 1, col = evid] amt can only be positive or zero when evid is one
   ```



8. Observation (`dv`) at the time of dose

   Observation should be `missing` at the time of dose (or when `amt` > 0)

   ```jldoctest
   df = DataFrame(id=[1,1], time=[0,1], amt=[10,0],
       				cmt=[1,2], evid=[1,0], dv=[10,8],
                   	age=[45,45], sex = ["M","M"])
   read_pumas(df, observations=[:dv], covariates=[:age, :sex])

   # output

   ERROR: PumasDataError: [Subject id: 1, row = 1, col = dv] an observation is present at the time of dose in column dv. It is recommended and required in Pumas to have a blank record (`missing`) at the time of dosing, i.e. when `amt` is positive
   ```



9. Steady-state column (`ss`) requires `ii` column

  ```jldoctest
  df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], ss=[1, 0],
            cmt=[1,2], dv=[missing,8], age=[45,45],
            sex = ["M","M"], evid=[1,0])
  read_pumas(df, observations=[:dv], covariates=[:age, :sex])

   # output

  ERROR: PumasDataError: your dataset does not have ii which is a required column for steady state dosing.
  ```


10. Steady-state dosing requires `ii` > 0

     Incase of steady-state dosing the value of the interval column `ii` must be non-zero

    If `rate` column is not provided it is assumed to be zero.

    ```jldoctest
    df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], ss=[1, 0], ii=[0,0],
                        cmt=[1,2], dv=[missing,8],
                        age=[45,45], sex = ["M","M"], evid=[1,0])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])

   # output

    ERROR: PumasDataError: [Subject id: 1, row = 1, col = ii] for steady-state dosing the value of the interval column ii must be non-zero but was 0
    ```

11. Steady-state infusion requires `ii` = 0

    Incase of steady-state infusion the value of the interval column `ii` must be zero

    ```jldoctest
    df = DataFrame(id=[1,1], time=[0,1], amt=[0,0], ss=[1, 0], rate=[2, 0], ii=[1, 0],
                cmt=[1,2], dv=[missing,8],
                      age=[45,45], sex = ["M","M"], evid=[1,0])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])

   # output

    ERROR: PumasDataError: [Subject id: 1, row = 1, col = ii] for steady-state infusion the value of the interval column ii must be zero but was 1
    ```

12. Steady-state infusion requires `addl` = 0

    Incase of steady-state infusion the value of the additional dose column `addl` must be zero

    ```jldoctest
    df = DataFrame(id=[1,1], time=[0,1], amt=[0,0], ss=[1, 0], rate=[2, 0], ii=[0, 0],
                addl=[5, 0], cmt=[1,2], dv=[missing,8],
                      age=[45,45], sex = ["M","M"], evid=[1,0])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])

   # output

    ERROR: PumasDataError: [Subject id: 1, row = 1, col = addl] for steady-state infusion the value of the additional dose column addl must be zero but was 5
    ```

13. `addl` column is present but `ii` is not

    ```jldoctest
    df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], addl=[5,0],
        				cmt=[1,2], evid=[1,0], dv=[missing,8],
                    	age=[45,45], sex = ["M","M"])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])

   # output

    ERROR: PumasDataError: your dataset does not have ii which is a required column when addl is specified.
    ```



14. `ii` must be positive for `addl > 0`

    ```jldoctest
    df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], addl=[5,0], ii=[0,0]
        				cmt=["Depot","Central"], evid=[1,0], dv=[missing,8],
                    	age=[45,45], sex = ["M","M"])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])

   # output

    ERROR: PumasDataError: [Subject id: 1, row = 1, col = ii]  ii must be positive for addl > 0
    ```



15. `addl` must be positive for `ii > 0`

    ```jldoctest
    df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], addl=[0,0], ii=[12,0],
        				cmt=["Depot","Central"], evid=[1,0], dv=[missing,8],
                    	age=[45,45], sex = ["M","M"])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])

   # output

    ERROR: PumasDataError: [Subject id: 1, row = 1, col = addl]  addl must be positive for ii > 0
    ```



16. `ii` can only be missing or zero when `evid = 0`

    ```jldoctest
    df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], addl=[5,2], ii=[12,4],
        				cmt=["Depot","Central"], evid=[1,0], dv=[missing,8],
                    	age=[45,45], sex = ["M","M"])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])

   # output

    ERROR: PumasDataError: [Subject id: 1, row = 2, col = evid]  ii can only be missing or zero when evid is zero
    ```



17. `addl` can only be positive or zero when `evid = 1`

    ```jldoctest
    df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], addl=[-10,0], ii=[12,0],
        				cmt=["Depot","Central"], evid=[1,0], dv=[missing,8],
                    	age=[45,45], sex = ["M","M"])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])

   # output

    ERROR: PumasDataError: [Subject id: 1, row = 1, col = evid]  addl can only be positive or zero when evid is one
    ```



18. `evid` must be nonzero when `amt` > 0 or `addl` and `ii` are positive

    When `amt` is positive, `evid` must be non-zero as `evid = 0 ` indicates an observation record.

    ```jldoctest
    df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], addl=[5,0], ii=[12,0],
        				cmt=["Depot","Central"], evid=[0,0], dv=[missing,8],
                    	age=[45,45], sex = ["M","M"])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])

   # output

    ERROR: PumasDataError: [Subject id: 1, row = 1, col = evid] amt can only be missing or zero when evid is zero
    ```

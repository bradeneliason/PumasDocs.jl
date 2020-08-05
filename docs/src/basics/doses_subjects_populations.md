# Dosage Regimens, Subjects, and Populations

The data is passed to a Pumas model via the `Population` type. A `Population` is
a collection of `Subject`s. In this section we will specify the methods used
for defining `Subject`s and `Population`s. These types can either be defined
programmatically using the `Subject` and `Population` constructors on Julia types
or by using the Pumas NLME Data format (named PumasNDF).

## Dosage Regimen Terminology

Both the `DosageRegimen` and the `PumasNDF` utilize the same terminology for
describing a dose. The definition of the values are as follows:

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

## The Subject Constructor

A `Subject` can be constructed using the following constructor:

```julia
Subject(;id = "1",
         observations = nothing,
         events = Event[],
         time = observations isa AbstractDataFrame ? observations.time : nothing,
         event_data = true,
         covariates::Union{Nothing, NamedTuple} = nothing,
         covariates_time = observations isa AbstractDataFrame ? observations.time : nothing,
         covariates_direction = :right)
```

The definitions of the arguments are as follows:

- `id` is the id of the subject. Defaults to `1`.
- `observations` is a Julia type which holds the observational data. When using the `@model` interface, this must be a `NamedTuple` whose names match those
  of the derived variables.
- `events` is a `DosageRegimen`. Defaults to an empty event list.
- `time` is the time when `observations` are measured
- `event_data` is a boolean which defaults to `true` and triggers that the specified events adhere to the PumasNDF(@ref). When set to `false`, the checks for `PumasNDF` are turned off.
- `covariates` are the covariates for the subject. It can be any Julia type when working with the function-based interface, but must be a `NamedTuple` for the `@model` interface. Defaults to `nothing`, meaning no covariates.
- `covariates_time` - #TODO
- `covariates_direction` - #TODO

### `DosageRegimen`

The `DosageRegimen` type is a specification of a regimen. Its constructor is:

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

Each of the values can either be `AbstractVector`s or scalars. All vectors must
be of the same length, and the elementwise combinations each define an event
(with scalars being repeated).

Additionally, multiple `DosageRegimen`s can be combined to form a `DosageRegimen`.
For example, if we have:

```julia
dr1 = DosageRegimen(100, ii = 24, addl = 6)
dr2 = DosageRegimen(50,  ii = 12, addl = 13)
dr3 = DosageRegimen(200, ii = 24, addl = 2)
```

then the following is the `DosageRegimen` for the combination of all doses:

```julia
dr = DosageRegimen(e1, e2, e3)
```

The current `DosageRegimen` can be viewed in its tabular form using the
`DataFrame` function: `DataFrame(dr)`.

One can also combine `DosageRegimen` while including a time `offset`

```julia
DosageRegimen(regimen1::DosageRegimen, regimen2::DosageRegimen; offset)
```

Here the second `DosageRegimen` after an `offset` time from the first. e.g. The second regimen below will start 10 hours after the last dosage regimen is completed.

```julia
DosageRegimen(dr1, dr2, offset = 10)
```

## The Population Constructor

The `Population` constructor is simply `Population(subjects)`, where
`subjects` is a collection of `Subject`s.

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

### PumasNDF Parsing

```julia
read_pumas(data; cvs=Symbol[],dvs=Symbol[:dv],
                 id=:id, time=:time, evid=:evid, amt=:amt, addl=:addl,
                 ii=:ii, cmt=:cmt, rate=:rate, ss=:ss)
```

The arguments are as follows:

- `data` is the tabular data source. If a string path to a CSV is given, then
  it will read the CSV file from that location in the file system. If a Julia-based
  tabular data structure is given, such as a
  [DataFrame](http://juliadata.github.io/DataFrames.jl/stable/), then that
  structure will be used as the data source.

The other arguments are optional (keyword arguments) and allow changing the column names from their
default.

### PumasNDF Checks
`read_pumas` function does some general checks on the provided data and informs the user about inconsistency in the data and throw an error in case of invalid data reporting row number and column name causing the problem so that user can look and resolve the issue.

Following is the list of checks applied by `read_pumas` function with examples.

1. Necessary columns in case of event and non-event data

   when the `event_data` is `true`, the dataset must contain `id, time, amt, and observations` columns.

   In case of `event_data = false`, only requirement is  `id`.

   ```julia
   df = DataFrame(id=[1,1], time=[0,1], cmt=[1,2], dv=[missing,8],
                   	age=[45,45], sex = ["M","M"], evid=[1,0])
   read_pumas(df, observations=[:dv], covariates=[:age, :sex], event_data=true)
   ```

   ```julia
   ┌ Info: The CSV file has keys: [:id, :time, :cmt, :dv, :age, :sex, :evid]
   └ @ Pumas /home/shubham00/.julia/dev/Pumas/src/data_parsing/io.jl:1023
   PumasDataError: The CSV file must have: `id, time, amt, and observations` when `event_data` is `true`
   ```



2. No `evid` column but `event_data` argument is set to `true`

   When provided dataset doesn't have `evid` column but `event_data=true` is passed to `read_pumas` function.

   ```julia
   df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], cmt=[1,2], dv=[missing,8],
                   	age=[45,45], sex = ["M","M"])
   read_pumas(df, observations=[:dv], covariates=[:age, :sex], event_data=true)
   ```

   ```julia
   ┌ Warning: Your dataset has dose event but it hasn't an evid column. We are adding 1 for dosing rows and 0 for others in evid column. If this is not the case, please add your evid column.
   ```



3. Non-numeric/string entries in an observation column

   If there are non-numeric or string entries in an observation column, `read_pumas` throws an error and reports row(s) and column(s) having this issue.

   ```julia
   df = DataFrame(id=[1,1], time=[0,1], amt=[10,0],
       				cmt=[1,2], dv=[missing,"k@"],
                   	age=[45,45], sex = ["M","M"], evid=[1,0])
   read_pumas(df, observations=[:dv], covariates=[:age, :sex])
   ```

   ```julia
   PumasDataError: [Subject id: [1], row = [2], col = dv]  We expect the dv column to be of numeric type.
   These are the unique non-numeric values present in the column dv: ("k@",)
   ```



4. Non-numeric/string entries in `amt`column

   This check is similar to above.

   ```julia
   df = DataFrame(id=[1,1], time=[0,1], amt=["k8",0],
       				cmt=[1,2], dv=[missing,8],
                   	age=[45,45], sex = ["M","M"], evid=[1,0])
   read_pumas(df, observations=[:dv], covariates=[:age, :sex])
   ```

   ```julia
   PumasDataError: [Subject id: [1], row = [1], col = amt]  We expect the amt column to be of numeric type.
   These are the unique non-numeric values present in the column amt: ("k8",)
   ```



5. `cmt` must be a positive integer or valid string/symbol for non-zero `evid` data record

   `cmt` column should contain positive numbers or string/symbol identifiers to compartment being dosed.

   ```julia
   df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], cmt=[-1,2], dv=[missing,8],
                   	age=[45,45], sex = ["M","M"], evid=[1,0])
   read_pumas(df, observations=[:dv], covariates=[:age, :sex])
   ```

   ```julia
   PumasDataError: [Subject id: 1, row = 1, col = cmt] cmt column should be positive
   ```



6. `amt` can only be `missing` or zero when `evid = 0`

   ```julia
   df = DataFrame(id=[1,1], time=[0,1], amt=[10,5], cmt=[1,2], dv=[missing,8],
                   	age=[45,45], sex = ["M","M"], evid=[1,0])
   read_pumas(df, observations=[:dv], covariates=[:age, :sex])
   ```

   ```julia
   PumasDataError: [Subject id: 1, row = 2, col = evid] amt can only be missing or zero when evid is zero
   ```



7. `amt` can only be positive or zero when `evid = 1`

   ```julia
   df = DataFrame(id=[1,1], time=[0,1], amt=[-10,0],
       				cmt=[1,2], evid=[1,0], dv=[10,8],
                   	age=[45,45], sex = ["M","M"])
   read_pumas(df, observations=[:dv], covariates=[:age, :sex])
   ```

   ```julia
   PumasDataError: [Subject id: 1, row = 1, col = evid] amt can only be positive or zero when evid is one
   ```



8. Observation (`dv`) at the time of dose

   Observation should be `missing` at the time of dose (or when `amt` > 0)

   ```julia
   df = DataFrame(id=[1,1], time=[0,1], amt=[10,0],
       				cmt=[1,2], evid=[1,0], dv=[10,8],
                   	age=[45,45], sex = ["M","M"])
   read_pumas(df, observations=[:dv], covariates=[:age, :sex])
   ```

   ```julia
   PumasDataError: [Subject id: 1, row = 1, col = dv] an observation is present at the time of dose in column dv. It is recommended and required in Pumas to have a blank record (`missing`) at the time of dosing, i.e. when `amt` is positive
   ```



9. Steady-state column (`ss`) requires `ii` column

  ```julia
  df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], ss=[1, 0],
            cmt=[1,2], dv=[missing,8], age=[45,45],
            sex = ["M","M"], evid=[1,0])
  read_pumas(df, observations=[:dv], covariates=[:age, :sex])
  ```

  ```julia
  ERROR: PumasDataError: your dataset does not have ii which is a required column for steady state dosing.
  ```


10. Steady-state dosing requires `ii` > 0

     Incase of steady-state dosing the value of the interval column `ii` must be non-zero

    If `rate` column is not provided it is assumed to be zero.

    ```julia
    df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], ss=[1, 0], ii=[0,0],
                        cmt=[1,2], dv=[missing,8],
                        age=[45,45], sex = ["M","M"], evid=[1,0])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])
    ```

    ```julia
    ERROR: PumasDataError: [Subject id: 1, row = 1, col = ii] for steady-state dosing the value of the interval column ii must be non-zero but was 0
    ```

11. Steady-state infusion requires `ii` = 0

    Incase of steady-state infusion the value of the interval column `ii` must be zero

    ```julia
    df = DataFrame(id=[1,1], time=[0,1], amt=[0,0], ss=[1, 0], rate=[2, 0], ii=[1, 0],
                cmt=[1,2], dv=[missing,8],
                      age=[45,45], sex = ["M","M"], evid=[1,0])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])
    ```

    ```julia
    ERROR: PumasDataError: [Subject id: 1, row = 1, col = ii] for steady-state infusion the value of the interval column ii must be zero but was 1
    ```

12. Steady-state infusion requires `addl` = 0

    Incase of steady-state infusion the value of the additional dose column `addl` must be zero

    ```julia
    df = DataFrame(id=[1,1], time=[0,1], amt=[0,0], ss=[1, 0], rate=[2, 0], ii=[0, 0],
                addl=[5, 0], cmt=[1,2], dv=[missing,8],
                      age=[45,45], sex = ["M","M"], evid=[1,0])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])
    ```

    ```julia
    ERROR: PumasDataError: [Subject id: 1, row = 1, col = addl] for steady-state infusion the value of the additional dose column addl must be zero but was 5
    ```

13. `addl` column is present but `ii` is not

    ```julia
    df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], addl=[5,0],
        				cmt=[1,2], evid=[1,0], dv=[missing,8],
                    	age=[45,45], sex = ["M","M"])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])
    ```

    ```julia
    PumasDataError: your dataset does not have ii which is a required column when addl is specified.
    ```



14. `ii` must be positive for `addl > 0`

    ```julia
    df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], addl=[5,0], ii=[0,0]
        				cmt=["Depot","Central"], evid=[1,0], dv=[missing,8],
                    	age=[45,45], sex = ["M","M"])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])
    ```

    ```julia
    PumasDataError: [Subject id: 1, row = 1, col = ii]  ii must be positive for addl > 0
    ```



15. `addl` must be positive for `ii > 0`

    ```julia
    df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], addl=[0,0], ii=[12,0],
        				cmt=["Depot","Central"], evid=[1,0], dv=[missing,8],
                    	age=[45,45], sex = ["M","M"])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])
    ```

    ```julia
    PumasDataError: [Subject id: 1, row = 1, col = addl]  addl must be positive for ii > 0
    ```



16. `ii` can only be missing or zero when `evid = 0`

    ```julia
    df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], addl=[5,2], ii=[12,4],
        				cmt=["Depot","Central"], evid=[1,0], dv=[missing,8],
                    	age=[45,45], sex = ["M","M"])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])
    ```

    ```julia
    PumasDataError: [Subject id: 1, row = 2, col = evid]  ii can only be missing or zero when evid is zero
    ```



17. `addl` can only be positive or zero when `evid = 1`

    ```julia
    df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], addl=[-10,0], ii=[12,0],
        				cmt=["Depot","Central"], evid=[1,0], dv=[missing,8],
                    	age=[45,45], sex = ["M","M"])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])
    ```

    ```julia
    PumasDataError: [Subject id: 1, row = 1, col = evid]  addl can only be positive or zero when evid is one
    ```



18. `evid` must be nonzero when `amt` > 0 or `addl` and `ii` are positive

    When `amt` is positive, `evid` must be non-zero as `evid = 0 ` indicates an observation record.

    ```julia
    df = DataFrame(id=[1,1], time=[0,1], amt=[10,0], addl=[5,0], ii=[12,0],
        				cmt=["Depot","Central"], evid=[0,0], dv=[missing,8],
                    	age=[45,45], sex = ["M","M"])
    read_pumas(df, observations=[:dv], covariates=[:age, :sex])
    ```

    ```julia
    PumasDataError: [Subject id: 1, row = 1, col = evid] amt can only be missing or zero when evid is zero
    ```

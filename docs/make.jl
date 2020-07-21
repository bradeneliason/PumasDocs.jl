using Documenter, Pumas
using Bioequivalence

ENV["COLUMNS"] = 90

DocMeta.setdocmeta!(Pumas, :DocTestSetup, :(using Pumas, Bioequivalence); recursive=true)

makedocs(
  modules=Module[Pumas, Bioequivalence],
  doctest=true,
  clean=true,
  format =Documenter.HTML(assets = [joinpath("assets", "custom.css")]),
  sitename="Pumas",
  authors="PumasAI",
  pages = Any[
    "Home" => "index.md",
    "Tutorials" => Any[
      "tutorials/introduction.md",
    ],
    "Basics" => Any[
      "basics/overview.md",
      "basics/models.md",
      "basics/doses_subjects_populations.md",
      "basics/simulation.md",
      "basics/estimation.md",
      "basics/nca.md",
      "basics/be.md",
      "basics/faq.md",
    ],
    "Model Components" => Any[
      "model_components/domains.md",
      "model_components/dosing_control.md",
      "model_components/dynamical_types.md",
    ],
    "Diagnostics" => Any[
      "analysis/diagnostics.md",
    ],
  ]
  )

deploydocs(
   repo = "github.com/PumasAI/PumasDocs.jl.git",
   push_preview = true,
)

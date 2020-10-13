using Documenter, AcqSynth

makedocs(
    sitename = "AcqSynth.jl",
    authors = "Jérémy Béjanin.",
    modules = [AcqSynth],
    linkcheck = true,
    clean = false,
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Home" => "index.md",
        "API" => [
            "api/helpers.md",
            "api/wrapper.md",
        ],
    ]
)

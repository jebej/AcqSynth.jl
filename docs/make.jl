using Documenter, AcqSynth

makedocs(
    sitename = "AcqSynth.jl",
    authors = "Jérémy Béjanin.",
    modules = [AcqSynth],
    linkcheck = true,
    clean = false,
    format = :html,
    html_prettyurls = false,
    pages = Any[
        "Home" => "index.md",
        "API" => Any[
            "api/helpers.md",
            "api/wrapper.md",
        ],
    ]
)

using JumpProcesses, Aqua, SciMLBase
@testset "Aqua" begin
    Aqua.find_persistent_tasks_deps(JumpProcesses)
    Aqua.test_ambiguities(JumpProcesses, recursive = false)
    Aqua.test_deps_compat(JumpProcesses)
    Aqua.test_piracies(JumpProcesses,
        treat_as_own = [SciMLBase.AbstractJumpProblem, SciMLBase.AbstractDEAlgorithm])
    Aqua.test_project_extras(JumpProcesses)
    Aqua.test_stale_deps(JumpProcesses)
    Aqua.test_unbound_args(JumpProcesses)
    Aqua.test_undefined_exports(JumpProcesses)
end

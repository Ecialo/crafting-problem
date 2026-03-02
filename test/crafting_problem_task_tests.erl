-module(crafting_problem_task_tests).
-include_lib("eunit/include/eunit.hrl").

%% tests for the topological sorting logic in crafting_problem_task

%% helper to make a minimal task map
make_task(Name, Req) ->
    #{name => Name, command => ~"cmd", requires => Req}.

graph_from_edges(EdgeMap) ->
    Vertices = maps:keys(EdgeMap),
    ToVerticies = maps:values(EdgeMap),
    AllVertices = lists:append([Vertices] ++ ToVerticies),
    UniqueVertices = sets:from_list(AllVertices),
    #{vertices => UniqueVertices, edges => EdgeMap}.

%% toposort tests

toposort_empty_test() ->
    Graph = crafting_problem_task:empty_task_graph(),
    ?assertEqual({ok, []}, crafting_problem_task:toposort(Graph)).

toposort_single_test() ->
    Graph = graph_from_edges(#{"a" => []}),
    ?assertEqual({ok, ["a"]}, crafting_problem_task:toposort(Graph)).

toposort_chain_test() ->
    %% a -> b -> c
    Graph = graph_from_edges(#{"a" => ["b"], "b" => ["c"], "c" => []}),
    {ok, Sorted} = crafting_problem_task:toposort(Graph),
    ?assertEqual(["a", "b", "c"], Sorted).

toposort_branching_test() ->
    %% a -> b,c   and   b -> d
    Graph = graph_from_edges(#{"a" => ["b", "c"], "b" => ["d"], "c" => [], "d" => []}),
    {ok, Sorted} = crafting_problem_task:toposort(Graph),
    %% valid order starts with a, d must come after b, c may interleave
    ?assert(lists:prefix(["a"], Sorted)),
    ?assert(lists:last(Sorted) =/= "a"),
    ?assert(lists:nth(2, Sorted) =:= "b" orelse lists:nth(2, Sorted) =:= "c").

toposort_cycle_test() ->
    Graph = graph_from_edges(#{"a" => ["b"], "b" => ["a"]}),
    ?assertEqual({error, cycle}, crafting_problem_task:toposort(Graph)).

%% tests for public sort_tasks_by_dependencies/1

sort_tasks_empty_test() ->
    ?assertEqual([], crafting_problem_task:sort_tasks_by_dependencies([])).

sort_tasks_linear_test() ->
    Tasks = [make_task("c", []), make_task("b", ["c"]), make_task("a", ["b"])],
    Sorted = crafting_problem_task:sort_tasks_by_dependencies(Tasks),
    case Sorted of
        {error, _} ->
            ?assert(false);
        _ ->
            Names = [maps:get(name, T) || T <- Sorted],
            ?assertEqual(["c", "b", "a"], Names)
    end.

sort_tasks_multiple_requirements_test() ->
    %% a requires b and c; b requires c
    Tasks = [make_task("c", []), make_task("b", ["c"]), make_task("a", ["b", "c"])],
    Sorted = crafting_problem_task:sort_tasks_by_dependencies(Tasks),
    case Sorted of
        {error, _} ->
            ?assert(false);
        _ ->
            Names = [maps:get(name, T) || T <- Sorted],
            %% c must be first, b second, a last
            ?assertEqual(["c", "b", "a"], Names)
    end.

sort_tasks_cycle_test() ->
    Tasks = [make_task("a", ["b"]), make_task("b", ["a"])],
    ?assertEqual({error, cycle}, crafting_problem_task:sort_tasks_by_dependencies(Tasks)).

sort_tasks_isolated_test() ->
    %% a task with no requirements and not required by any other task
    %% must still appear in the sorted output
    Tasks = [make_task("x", [])],
    Sorted = crafting_problem_task:sort_tasks_by_dependencies(Tasks),
    case Sorted of
        {error, _} ->
            ?assert(false);
        _ ->
            Names = [maps:get(name, T) || T <- Sorted],
            ?assertEqual(["x"], Names)
    end.

sort_tasks_bad_task_id_test() ->
    %% a task that requires a non-existent task should cause an error
    Tasks = [make_task("a", ["nonexistent"])],
    ?assertEqual({error, bad_task_id}, crafting_problem_task:sort_tasks_by_dependencies(Tasks)).

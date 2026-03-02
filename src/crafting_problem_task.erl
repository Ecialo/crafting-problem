-module(crafting_problem_task).

-export_type([task/0, task_name/0, task_lib/0, error/0]).
-export([
    from_raw/1,
    to_compact/1,
    build_task_lib/1,
    sort_tasks_by_dependencies/1,
    empty_task_graph/0,
    toposort/1
]).

-type task_name() :: string().
-type task_lib() :: #{task_name() => task()}.
-type task_graph() :: #{
    vertices := sets:set(),
    edges := #{task_name() => [task_name()]}
}.

-type task() :: #{
    name := task_name(),
    command := binary(),
    requires := [task_name()]
}.

-type error() :: {error, cycle | bad_task_id}.

-spec from_raw(map()) -> task().
from_raw(RawTask) ->
    #{
        name => maps:get(~"name", RawTask),
        command => maps:get(~"command", RawTask),
        requires => maps:get(~"requires", RawTask, [])
    }.

-spec to_compact(task()) -> map().
to_compact(Task) -> maps:remove(requires, Task).

-spec build_task_lib([task()]) -> task_lib().
build_task_lib(Tasks) ->
    lists:foldl(
        fun(Task, Acc) ->
            Name = maps:get(name, Task),
            Acc#{Name => Task}
        end,
        #{},
        Tasks
    ).

-spec sort_tasks_by_dependencies([task()]) -> error() | [task()].
sort_tasks_by_dependencies(Tasks) ->
    TaskLib = build_task_lib(Tasks),
    TaskNames = maps:keys(TaskLib),
    TaskNamesSet = sets:from_list(TaskNames),
    AllRequiresExist = lists:all(
        fun(#{requires := Requires}) ->
            lists:all(fun(R) -> sets:is_element(R, TaskNamesSet) end, Requires)
        end,
        Tasks
    ),
    case AllRequiresExist of
        false ->
            {error, bad_task_id};
        true ->
            Graph = build_dependency_graph(Tasks),
            case toposort(Graph) of
                {ok, Names} ->
                    lists:map(fun(Name) -> maps:get(Name, TaskLib) end, Names);
                Error = {error, _} ->
                    Error
            end
    end.

-spec build_dependency_graph([task()]) -> task_graph().
build_dependency_graph(Tasks) ->
    lists:foldl(
        fun(Task, Acc) ->
            update_task_graph(Acc, Task)
        end,
        empty_task_graph(),
        Tasks
    ).

-spec empty_task_graph() -> task_graph().
empty_task_graph() ->
    #{vertices => sets:new(), edges => #{}}.

-spec get_vertex_neighbors(task_graph(), task_name()) -> [task_name()].
get_vertex_neighbors(#{edges := Edges}, Node) ->
    maps:get(Node, Edges, []).

-spec update_task_graph(task_graph(), task()) -> task_graph().
update_task_graph(#{vertices := Vertices, edges := Edges}, #{name := Name, requires := Requires}) ->
    TaskGraph1 = #{vertices => sets:add_element(Name, Vertices), edges => Edges},
    lists:foldl(
        fun(Req, #{vertices := V, edges := E}) ->
            #{
                vertices => V,
                edges => maps:update_with(Req, fun(Deps) -> [Name | Deps] end, [Name], E)
            }
        end,
        TaskGraph1,
        Requires
    ).

-spec toposort(task_graph()) -> {error, cycle} | {ok, [task_name()]}.
toposort(Graph = #{vertices := Vertices}) ->
    Visited = sets:new(),
    OnPath = sets:new(),
    ListVertices = sets:to_list(Vertices),

    Result = lists:foldl(
        fun visit/2,
        {Graph, Visited, OnPath, []},
        ListVertices
    ),
    case Result of
        {_, _, _, Sorted} -> {ok, Sorted};
        Error = {error, _} -> Error
    end.

visit(Node, {Graph, Visited, OnPath, Sorted}) ->
    IsCycle = sets:is_element(Node, OnPath),
    IsVisited = sets:is_element(Node, Visited),
    case {IsCycle, IsVisited} of
        {true, _} ->
            {error, cycle};
        {false, true} ->
            {Graph, Visited, OnPath, Sorted};
        {false, false} ->
            Neighbors = get_vertex_neighbors(Graph, Node),
            OnPath1 = sets:add_element(Node, OnPath),
            Result = lists:foldl(
                fun visit/2,
                {Graph, Visited, OnPath1, Sorted},
                Neighbors
            ),
            case Result of
                Error = {error, _} ->
                    Error;
                {_, Visited2, _OnPath2, Sorted2} ->
                    Visited3 = sets:add_element(Node, Visited2),
                    {Graph, Visited3, OnPath, [Node | Sorted2]}
            end
    end;
visit(_Node, Error = {error, _}) ->
    Error.

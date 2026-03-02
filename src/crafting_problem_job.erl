-module(crafting_problem_job).

-export([parse_job/1, to_compact/1, from_raw/1]).
-export_type([job/0]).

-type job() :: #{tasks := [crafting_problem_task:task()]}.

-spec parse_job(binary()) -> job().
parse_job(Json) ->
    {Result, _, _} = json:decode(Json, ok, #{object_finish => fun object_finish/2}),
    Result.

-spec from_raw(map()) -> job().
from_raw(RawJob) ->
    #{tasks => maps:get(~"tasks", RawJob, [])}.

-spec to_compact(job()) -> map().
to_compact(#{tasks := Tasks}) ->
    #{tasks => lists:map(fun crafting_problem_task:to_compact/1, Tasks)}.

%% Parser callback
object_finish(Acc, OldAcc) ->
    Object = maps:from_list(Acc),
    Result =
        case Object of
            #{~"tasks" := _Tasks} -> from_raw(Object);
            #{~"name" := _Name} -> crafting_problem_task:from_raw(Object);
            %% maybe it's a good idea to throw an error here if the object doesn't match expected structures
            Other -> Other
        end,
    {Result, OldAcc}.

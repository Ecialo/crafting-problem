-module(crafting_problem_job_tests).
-include_lib("eunit/include/eunit.hrl").

%% simple tests for parse_job/1 and helpers

parse_job_basic_test() ->
    Json = ~"{\"tasks\":[{\"name\":\"a\",\"command\":\"do\",\"requires\":[] }]}",
    Job = crafting_problem_job:parse_job(Json),
    ?assert(is_map(Job)),
    Tasks = maps:get(tasks, Job),
    ?assertEqual(1, length(Tasks)),
    Task = hd(Tasks),
    ?assertEqual(~"a", maps:get(name, Task)),
    ?assertEqual(~"do", maps:get(command, Task)),
    ?assertEqual([], maps:get(requires, Task)).

parse_job_empty_tasks_test() ->
    %% when tasks key is present but empty
    Json = ~"{\"tasks\":[]}",
    Job = crafting_problem_job:parse_job(Json),
    ?assert(is_map(Job)),
    ?assertEqual([], maps:get(tasks, Job)).

parse_job_no_tasks_key_test() ->
    %% top-level object without tasks should round-trip as plain map
    Json = ~"{}",
    Job = crafting_problem_job:parse_job(Json),
    ?assertEqual(#{}, Job).

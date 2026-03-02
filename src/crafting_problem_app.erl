-module(crafting_problem_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/api/job/sort-tasks", crafting_problem_handler, sort},
            {"/api/job/compile-command", crafting_problem_handler, compile_script}
        ]}
    ]),
    {ok, _} = cowboy:start_clear(
        crafting_problem_listener,
        [{port, 8080}],
        #{env => #{dispatch => Dispatch}}
    ),
    crafting_problem_sup:start_link().

stop(_State) ->
    ok.

%% internal functions

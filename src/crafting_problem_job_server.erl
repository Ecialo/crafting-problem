-module(crafting_problem_job_server).
-behaviour(gen_server).

-define(SHABANG, ~"#!/usr/bin/env bash").

-export([
    init/1,
    handle_call/3,
    sort_tasks/1,
    compile_script/1,
    handle_cast/2,
    start_link/0,
    start_link/1
]).

init(_) ->
    {ok, #{}}.

start_link() ->
    start_link([]).

start_link(_) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

sort_tasks(Job) ->
    gen_server:call(?MODULE, {sort_tasks, Job}).

compile_script(Job) ->
    gen_server:call(?MODULE, {compile_script, Job}).

handle_call({sort_tasks, #{tasks := Tasks}}, _From, State) ->
    Result = crafting_problem_task:sort_tasks_by_dependencies(Tasks),
    case Result of
        Error = {error, _} ->
            {reply, Error, State};
        SortedTasks ->
            SortedJob = #{tasks => SortedTasks},
            {reply, SortedJob, State}
    end;
handle_call({compile_script, Job}, _From, State) ->
    Result = do_compile_script(Job),
    {reply, Result, State};
handle_call(_Request, _From, State) ->
    {reply, {error, bad_request}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

-spec do_compile_script(crafting_problem_job:job()) -> binary() | crafting_problem_task:error().
do_compile_script(#{tasks := Tasks}) ->
    SortedTasksResult = crafting_problem_task:sort_tasks_by_dependencies(Tasks),
    case SortedTasksResult of
        Error = {error, _} ->
            Error;
        SortedTasks ->
            Commands = lists:map(fun(#{command := CMD}) -> CMD end, SortedTasks),
            ResultScript = [?SHABANG | Commands],
            binary:join(ResultScript, ~"\n")
    end.

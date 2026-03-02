-module(crafting_problem_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
    SupFlags = #{
        strategy => one_for_all,
        intensity => 1,
        period => 5
    },
    ChildSpecs = [
        #{
            id => crafting_problem_job_server,
            start => {crafting_problem_job_server, start_link, []},
            restart => permanent,
            type => worker,
            modules => [crafting_problem_job_server]
        }
    ],
    {ok, {SupFlags, ChildSpecs}}.

%% internal functions

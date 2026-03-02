-module(crafting_problem_handler).
-behaviour(cowboy_rest).
-define(JSON_CONTENT_TYPE, ~"application/json").
-define(PLAIN_TEXT_CONTENT_TYPE, ~"text/plain").

-export([
    init/2,
    allowed_methods/2,
    content_types_accepted/2,
    handle_post/2
]).

-type state() :: sort | compile_script.

-spec init(cowboy_req:req(), state()) -> {cowboy_rest, cowboy_req:req(), state()}.
init(Req, State) ->
    {cowboy_rest, Req, State}.

-spec allowed_methods(cowboy_req:req(), state()) -> {list(binary()), cowboy_req:req(), state()}.
allowed_methods(Req, State) ->
    {[~"POST"], Req, State}.

-spec content_types_accepted(cowboy_req:req(), state()) ->
    {
        list(
            {binary(), atom()}
        ),
        cowboy_req:req(),
        state()
    }.
content_types_accepted(Req, State) ->
    {
        [
            {~"application/json", handle_post}
        ],
        Req,
        State
    }.

-spec handle_post(cowboy_req:req(), state()) -> {stop, cowboy_req:req(), state()}.
handle_post(Req, State) ->
    {ok, Data, Req1} = cowboy_req:read_body(Req),
    Job = crafting_problem_job:parse_job(Data),
    Req2 =
        case State of
            sort ->
                SortedJob = crafting_problem_job_server:sort_tasks(Job),
                maybe_respond_with_json(Req1, SortedJob);
            compile_script ->
                Script = crafting_problem_job_server:compile_script(Job),
                maybe_respond_with_plaintext(Req1, Script);
            _ ->
                Req1
        end,

    {stop, Req2, State}.

maybe_respond_with_json(Req, Error = {error, _}) ->
    set_bad_data_response(Req, Error);
maybe_respond_with_json(Req, Job) ->
    CompactJob = crafting_problem_job:to_compact(Job),
    Body = json:encode(CompactJob),
    cowboy_req:reply(200, #{~"content-type" => ?JSON_CONTENT_TYPE}, Body, Req).

maybe_respond_with_plaintext(Req, Error = {error, _}) ->
    set_bad_data_response(Req, Error);
maybe_respond_with_plaintext(Req, Script) ->
    cowboy_req:reply(200, #{~"content-type" => ?PLAIN_TEXT_CONTENT_TYPE}, Script, Req).

set_bad_data_response(Req, {error, cycle}) ->
    cowboy_req:reply(
        400, #{~"content-type" => ?PLAIN_TEXT_CONTENT_TYPE}, ~"Bad data: cycle found\n", Req
    );
set_bad_data_response(Req, {error, bad_request}) ->
    %% Should be never called
    cowboy_req:reply(
        400, #{~"content-type" => ?PLAIN_TEXT_CONTENT_TYPE}, ~"Some unexpected bad request\n", Req
    );
set_bad_data_response(Req, {error, bad_task_id}) ->
    cowboy_req:reply(
        400,
        #{~"content-type" => ?PLAIN_TEXT_CONTENT_TYPE},
        ~"Bad data: found bad task id in requires\n",
        Req
    ).

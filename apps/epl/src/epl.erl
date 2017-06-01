%%
%% %CopyrightBegin%
%%
%% Copyright Michal Slaski 2013. All Rights Reserved.
%%
%% %CopyrightEnd%
%%
-module(epl).
-include_lib("epl/include/epl.hrl").

-export([lookup/1,
         subscribe/0,
         subscribe/1,
         subscribe/2,
         unsubscribe/0,
         unsubscribe/1,
         unsubscribe/2,
         command/2,
         command/3,
         process_info/1,
         trace_pid/1,
         to_bin/1,
         log/3,
         timestamp/1
        ]).

%% ===================================================================
%% API functions
%% ===================================================================

%% Lookup for given Key in epl_priv ets
-spec lookup(Key :: term()) -> [tuple()].
lookup(Key) ->
    ets:lookup(epl_priv, Key).

%% Add calling process to every epl_tracers' subscribers list
-spec subscribe() -> [ok].
subscribe() ->
    Nodes = get_all_nodes(),
    [subscribe(N) || N <- Nodes].

%% Add calling process to Node tracer's subscribers list
-spec subscribe(default_node) -> ok;
               (Node :: atom()) -> ok.
subscribe(default_node) ->
    Node = get_default_node(),
    subscribe(Node);
subscribe(Node) ->
    subscribe(Node, self()).

%% Add provided Pid to Node tracer's subscribers list
-spec subscribe(Node :: atom(), Pid :: pid()) -> ok.
subscribe(Node, Pid) ->
    epl_tracer:subscribe(Node, Pid).

%% Remove calling process from every epl_tracers' subscribers list
-spec unsubscribe() -> [ok].
unsubscribe() ->
    Nodes = get_all_nodes(),
    [unsubscribe(N) || N <- Nodes].

%% Remove calling process from Node tracer's subscribers list
-spec unsubscribe(default_node) -> ok;
                 (Node :: atom()) -> ok.
unsubscribe(default_node) ->
    Node = get_default_node(),
    unsubscribe(Node);
unsubscribe(Node) ->
    unsubscribe(Node, self()).

%% Remove provided Pid from Node tracer's subscribers list
-spec unsubscribe(Node :: atom(), Pid :: pid()) -> ok.
unsubscribe(Node, Pid) ->
    epl_tracer:unsubscribe(Node, Pid).

%% Run provided Fun with Args on every observed nodes
-spec command(Fun :: fun(), Args :: list()) -> [tuple()].
command(Fun, Args) ->
    Nodes = get_all_nodes(),
    [command(N, Fun, Args) || N <- Nodes].

%% Run provided Fun with Args on default/provided node
-spec command(default_node, Fun :: fun(), Args :: list()) -> tuple();
             (Node :: atom(), Fun :: fun(), Args :: list()) -> tuple().
command(default_node, Fun, Args) ->
    Node = get_default_node(),
    command(Node, Fun, Args);
command(Node, Fun, Args) ->
    epl_tracer:command(Node, Fun, Args).

%% Get information about process identified by provided Pid
-spec process_info(Pid :: pid()) -> tuple().
process_info(Pid) ->
    Node = erlang:node(Pid),
    epl_tracer:command(Node, fun erlang:process_info/1, [Pid]).

%% Trace provied Pid
-spec trace_pid(Pid :: pid()) -> ok.
trace_pid(Pid) ->
    epl_tracer:trace_pid(Pid).

to_bin(I) when is_atom(I)      -> list_to_binary(atom_to_list(I));
to_bin(I) when is_integer(I)   -> list_to_binary(integer_to_list(I));
to_bin(I) when is_pid(I)       -> list_to_binary(pid_to_list(I));
to_bin(I) when is_port(I)      -> list_to_binary(erlang:port_to_list(I));
to_bin(I) when is_reference(I) -> list_to_binary(erlang:ref_to_list(I));
to_bin(I) when is_float(I)     -> list_to_binary(float_to_list(I));
to_bin(I) when is_function(I)  -> list_to_binary(erlang:fun_to_list(I));
to_bin(I) when is_binary(I)    -> I;
to_bin(I) when is_list(I)      -> case catch list_to_binary(I) of
                                      {'EXIT', {badarg,_}} ->
                                          [to_bin(El) || El <- I];
                                      B ->
                                          B
                                  end.

log(Level, Str, Args) ->
    [{log_level, LogLevel}] = lookup(log_level),
    case should_log(LogLevel, Level) of
        true ->
            io:format(log_prefix(Level) ++ Str, Args);
        false ->
            ok
    end.

timestamp(TS) ->
    {{Y,M,D},{H,Mi,S}} = calendar:now_to_local_time(TS),
    DT = [integer_to_list(Y),
          io_lib:format("~.2.0w",[M]),
          io_lib:format("~.2.0w",[D]),
          $_,
          io_lib:format("~.2.0w",[H]),
          io_lib:format("~.2.0w",[Mi]),
          io_lib:format("~.2.0w",[S])],
    to_bin(DT).

%% ===================================================================
%% internal functions
%% ===================================================================

should_log(debug, _)     -> true;
should_log(info, debug)  -> false;
should_log(info, _)      -> true;
should_log(warn, debug)  -> false;
should_log(warn, info)   -> false;
should_log(warn, _)      -> true;
should_log(error, error) -> true;
should_log(error, _)     -> false;
should_log(_, _)         -> false.

log_prefix(debug) -> "DEBUG: ";
log_prefix(info)  -> "INFO:  ";
log_prefix(warn)  -> "WARN:  ";
log_prefix(error) -> "ERROR: ".

get_all_nodes() ->
    erlang:nodes().

get_default_node() ->
    [{node, Node}] = lookup(node),
    Node.

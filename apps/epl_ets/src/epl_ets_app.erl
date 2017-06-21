%%%-------------------------------------------------------------------
%% @doc epl_ets public API
%% @end
%%%-------------------------------------------------------------------

-module(epl_ets_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    epl_ets_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================
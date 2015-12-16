-module(learn_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
  Dispatch = cowboy_router:compile([
    {'_', [
      {"/api/[...]", acl_handler, []},
      {"/check", paymnt_handler, []},
      {"/pay", paymnt_handler, []},
      {"/status", paymnt_handler, []},
      {'_', notfound_handler, []}
    ]}
  ]),
  Port = 8008,
  {ok, _} = cowboy:start_http(http_listener, 100,
    [{port, Port}],
    [{env, [{dispatch, Dispatch}]}]
  ),
    learn_sup:start_link().



stop(_State) ->
    ok.

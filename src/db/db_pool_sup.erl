%%%-------------------------------------------------------------------
%%% @author Vitali Kletsko
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. июн 2015 16:34
%%%-------------------------------------------------------------------
-module(db_pool_sup).
-author("Vitali KLetsko <v.kletsko@gmail.com>").

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-include("template.hrl").

%%%===================================================================
%%% API functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the supervisor
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link() ->
  {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================
-spec(init(Args :: term()) ->
  {ok, {SupFlags :: {RestartStrategy :: supervisor:strategy(),
    MaxR :: non_neg_integer(), MaxT :: non_neg_integer()},
    [ChildSpec :: supervisor:child_spec()]
  }} |
  ignore |
  {error, Reason :: term()}).
init([]) ->
  {ok, Configs} = application:get_env(learn, db_pool_conf),
  PoollSpecs = get_pool_specifications(Configs),
  {ok, {{one_for_one, 10, 10}, PoollSpecs}}.

get_pool_specifications(Pools) ->
  ?LOG_DEBUG("Xaxa DB ~p~n ",[{Pools}]),
  lists:map(fun({Name, SizeArgs, WorkerArgs}) ->
    PoolArgs = [{name, {local, Name}},
    {worker_module, db_pool_worker}] ++ SizeArgs,
    poolboy:child_spec(Name, PoolArgs, WorkerArgs)
  end, Pools).









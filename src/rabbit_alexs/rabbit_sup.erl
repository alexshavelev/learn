%%%-------------------------------------------------------------------
%%% @author user
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. фев 2015 12:17
%%%-------------------------------------------------------------------
-module(rabbit_sup).
-author("user").

-include("template.hrl").

%% API

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

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


-spec(init(Args :: term()) ->
  {ok, {SupFlags :: {RestartStrategy :: supervisor:strategy(),
    MaxR :: non_neg_integer(), MaxT :: non_neg_integer()},
    [ChildSpec :: supervisor:child_spec()]
  }} |
  ignore |
  {error, Reason :: term()}).

init([]) ->
  {ok, Configs} = application:get_env(learn, rabbit_pool_conf ),
  PoollSpecs = get_pool_specifications(Configs),
  ?LOG_DEBUG("Configs ~p~n" ,[Configs]),
  {ok, {{one_for_one, 10, 10}, PoollSpecs}}.


get_pool_specifications(Pools) ->
  ?LOG_DEBUG("Xaxa ~p~n",[{Pools}]),
  lists:map(fun({Name, SizeArgs, WorkerArgs}) ->
    PoolArgs = [{name, {local, Name}},
      {worker_module, rabbit_worker}] ++ SizeArgs,
    poolboy:child_spec(Name, PoolArgs, WorkerArgs)
  end, Pools).




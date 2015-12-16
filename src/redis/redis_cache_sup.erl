%%%-------------------------------------------------------------------
%%% @author Vitali Kletsko
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. июн 2015 16:34
%%%-------------------------------------------------------------------
-module(redis_cache_sup).
-author("Vitali KLetsko <v.kletsko@gmail.com>").

-behaviour(supervisor).
-include("template.hrl").

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
  {ok, Configs} = application:get_env(learn, redis_pool_conf),
  PoollSpecs = get_pool_specifications(Configs),
  ?LOG_DEBUG("Configs ~p~n" ,[Configs]),
  {ok, {{one_for_one, 10, 10}, PoollSpecs}}.

%% get_pool_specifications(Pools) ->
%%   lists:map(fun({Name, SizeArgs, WorkerArgs}) ->
%%     PoolArgs = [{name, {local, Name}},
%%     {worker_module, redis_pool_worker}] ++ SizeArgs,
%%     poolboy:child_spec(Name, PoolArgs, WorkerArgs)
%%   end, Pools).


get_pool_specifications(Pools) ->
  lists:map(fun({Name, SizeArgs, WorkerArgs}) ->
    PoolArgs = [{name, {local, Name}},
      {worker_module, redis_cache_worker}] ++ SizeArgs,
    poolboy:child_spec(Name, PoolArgs, WorkerArgs)
  end, Pools).















%% -behaviour(supervisor).
%%
%% %% API
%% -export([start_link/0, get_cache_pools/0, cache_query/2, session_pool_cache_query/1]).
%%
%% %% Supervisor callbacks
%% -export([init/1]).
%% -include("template.hrl").
%%
%% -define(SERVER, ?MODULE).
%% -define(NEW_SESSION_STORAGE_POOLNAME, "session_storage_pool_new").
%% -define(OLD_SESSION_STORAGE_POOLNAME, "session_storage_pool_old").
%%
%% -define(CACHE_POOLS, [
%%   ?NEW_SESSION_STORAGE_POOLNAME,
%%   ?OLD_SESSION_STORAGE_POOLNAME
%% ]).
%%
%% %%%===================================================================
%% %%% API functions
%% %%%===================================================================
%%
%% %%--------------------------------------------------------------------
%% %% @doc
%% %% Starts the supervisor
%% %%
%% %% @end
%% %%--------------------------------------------------------------------
%% -spec(start_link() ->
%%   {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
%% start_link() ->
%%   supervisor:start_link({local, ?SERVER}, ?MODULE, []).
%%
%% %%%===================================================================
%% %%% Supervisor callbacks
%% %%%===================================================================
%%
%% %%--------------------------------------------------------------------
%% %% @private
%% %% @doc
%% %% Whenever a supervisor is started using supervisor:start_link/[2,3],
%% %% this function is called by the new process to find out about
%% %% restart strategy, maximum restart frequency and child
%% %% specifications.
%% %%
%% %% @end
%% %%--------------------------------------------------------------------
%%
%% -spec(init(Args :: term()) ->
%%   {ok, {SupFlags :: {RestartStrategy :: supervisor:strategy(),
%%     MaxR :: non_neg_integer(), MaxT :: non_neg_integer()},
%%     [ChildSpec :: supervisor:child_spec()]
%%   }} |
%%   ignore |
%%   {error, Reason :: term()}).
%% init([]) ->
%%   {ok, Configs} = application:get_env(learn, redis_pool_conf),
%%   PoollSpecs = get_pool_specifications(Configs),
%%   {ok, {{one_for_one, 10, 10}, PoollSpecs}}.
%%
%%
%% %% SizeArgs_Root   = [ {max_size, MaxSize}, {min_size, MinSize}, {start_size, StartSize} ],
%% %% WorkerArgs_Root = [ {hostname, Host}, {database, Database},  {port, Port}, {password, Password} ],
%% %%
%% %% PoolArgs = [{name, {local, PollName}}, {worker_module, redis_worker_server}] ++ SizeArgs_Root,
%% %%
%% %% PoolSpecsFull = [poolboy:child_spec(PollName, PoolArgs, WorkerArgs_Root)],
%% get_pool_specifications(Configs) ->
%%   lists:map(fun(PoolName) ->
%%
%%     PoolNameInLowerCaseAtom = to_lower_atom(PoolName),
%%     PoolConf = proplists:get_value(PoolNameInLowerCaseAtom, Configs),
%%
%%     {MaxSize, MinSize, StartSize} = get_poolboy_config(PoolConf),
%%     PoolboySizeSpec   = [ {max_size, MaxSize}, {min_size, MinSize}, {start_size, StartSize} ],
%%
%%     PoolArgs = [{name, {local, PoolNameInLowerCaseAtom}}, {worker_module, redis_cache_worker}] ++ PoolboySizeSpec,
%%
%%     poolboy:child_spec(PoolNameInLowerCaseAtom, PoolArgs, PoolConf)
%%
%%
%%   end, ?CACHE_POOLS).
%%
%% get_poolboy_config(PoolConf) ->
%%   {
%% %%     proplists:get_value(max_size, PoolConf),
%% %%     proplists:get_value(min_size, PoolConf),
%% %%     proplists:get_value(start_size, PoolConf)
%%         proplists:get_value(size, PoolConf),
%%         proplists:get_value(max_overflow, PoolConf)
%%
%%   }.
%%
%% to_lower_atom(PoolName) when is_list(PoolName) ->
%%   list_to_atom(string:to_lower(PoolName));
%% to_lower_atom(PoolName)-> eu_types:to_list(PoolName).
%%
%% %%%===================================================================
%% %%% Internal functions
%% %%%===================================================================
%% get_cache_pools()-> ?CACHE_POOLS.
%%
%% session_pool_cache_query(Query)->
%%   cache_query(Query, session_storage_pool_new).
%%
%% %% Answers from eredis driver
%% %% {ok, return_value()} | {error, Reason::binary() | no_connection}.
%% cache_query(PoolName, Query) when is_atom(PoolName) andalso is_list(Query)->
%%   cache_query(Query, PoolName);
%% cache_query(Query, PoolName) when is_list(Query) andalso is_atom(PoolName) ->
%%   poolboy:transaction(PoolName,
%%     fun(Worker) ->
%%       case catch gen_server:call(Worker, {equery, Query}, 10000) of
%%         {ok, CacheResp} when is_binary(CacheResp) orelse is_atom(CacheResp) orelse is_list(CacheResp) -> CacheResp;
%%         {error, _} =ErResp -> ErResp;
%%         no_connection ->
%%           Worker ! connect,
%%           {error, <<"redis worker connection lost">>};
%%         ErrorResp ->
%%           ?LOG_ERROR("cache_query error occured with reason ~p", [ErrorResp]),
%%           {error, unicode:characters_to_binary(term_to_binary(ErrorResp))}
%%       end
%%     end).





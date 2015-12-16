-module(learn_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, learn_acl).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init(_) ->
    create_tables(),
    {ok, { {one_for_one, 5, 10}, [
		  ?CHILD(learn_achl2, worker),
      ?CHILD(learn_acl, worker),
      ?CHILD(learn_paymnt, worker),
      ?CHILD(db_pool_sup, supervisor),
      ?CHILD(redis_cache_sup, supervisor),
      ?CHILD(rabbit_sup, supervisor)
	]}} .




create_tables() ->
  ets:new(users_our, [set, named_table, public, {keypos, 1}]),
  ets:new(payments, [set, named_table, public, {keypos, 1}]).



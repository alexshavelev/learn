-module(redis_cache).
-author("Vitali Kletsko <v.kletsko@gmail.com>").

%% API
-export([
  %init/0,
  %% high level
  %save/1,
  %save/2,
  %get_session_data/2,
  %drop_session/1,

  %% Low level
  cache_query/1,

  setex/2,
  set/2,
  set/3,

  hset/2,
  hget/2,
  hgetall/1,
  get_data/1,
  multi_set/1,
  multi_get/1,
  multi_delete/1,
  delete/1,

  is_exist/1,

  set_expire_sec/2,
  set_expire_milisec/2,
  set_expire_timestamp/2,
  remove_expire/1,

  find_keys_by_pattern/1,
  increment/1,

  transaction_open/0,
  transaction_commit/0
  , decrement/1]).

-include("template.hrl").

-define(SERVER, ?MODULE).

-define(LIFE_SESSION, 900).

-define(WORKER_TIMEOUT, 5000).

%%%===================================================================
%%% API
%%%===================================================================
-spec transaction_open()-> Value :: binary().
transaction_open() ->
  Query = ["MULTI"],
  cache_query(Query).
-spec transaction_commit() -> Value :: binary().
transaction_commit() ->
  Query = ["EXEC"],
  cache_query(Query).

-spec multi_get(Keys :: tuple()) -> ReturnValue :: list() | {error, Reason::binary() | no_connection}.
multi_get(Keys) when is_tuple(Keys)->
  multi_get(tuple_to_list(Keys));
multi_get(Keys)->
  Query = ["MGET" | [Keys]],
  cache_query(Query).

multi_set(KeyValuePairs) when is_tuple(KeyValuePairs) ->
  multi_set(tuple_to_list(KeyValuePairs));
multi_set([KeyValuePair | Pairs]) when is_tuple(KeyValuePair) ->
  KeyValueList = proplists_to_list([KeyValuePair | Pairs], []),
  Query = ["MSET" | KeyValueList],
  ?LOG_INFO("MULTI SET QUERY FOR PROPLIST: ~p~n", [Query]),
  cache_query(Query);
multi_set([KeyValuePair | []])  ->
  Query = ["SET" | KeyValuePair],
  cache_query(Query);
multi_set(KeyValuePairs) ->
  cache_query(["MSET" | KeyValuePairs]).

-spec multi_delete(Keys :: [string()] ) -> integer().
multi_delete(Keys) ->
  Query = ["DEL" | Keys],
  cache_query(Query).

-spec get_data(Key :: string())->
  Value :: binary() | {error, binary()}.
get_data(Key)->
  Query = ["GET", Key],
  cache_query(Query).

-spec set(Key:: string(), Value :: string()) ->
  ConfirmOK :: binary() | {error, binary()}.
set(Key, Value)->
  Query = ["SET", Key, Value],
  ?LOG_DEBUG("Input SET ~p~n", [Value]),
  cache_query(Query).

-spec setex(Key:: string(), Value :: string()) ->
  ConfirmOK :: binary() | {error, binary()}.
setex(Key, Value)->
  Query = ["SETEX", Key, ?LIFE_SESSION, Value],
  cache_query(Query).
-spec set(Key :: string(), Value :: string(), Expire :: integer()) -> ConfirmOK :: binary() | {error, binary()}.
set(Key, Value, Expire) ->
  Query = ["SET", Key, Value],
  QueryRes = cache_query(Query),
  case QueryRes of
    <<"OK">> -> set_expire_sec(Key, Expire);
    _ -> QueryRes
  end.
-spec delete(Key :: string()) ->
  Value :: binary().
delete(Key)->
  Query = ["DEL", Key],
  cache_query(Query).

-spec is_exist(Key :: string()) ->
  Value :: boolean() | {error, binary()}.
is_exist(Key)->
  Query = ["EXISTS", Key],
  Result = cache_query(Query),
  case Result of
    <<"0">> -> false;
    <<"1">> -> true
  end.

%% SET EXPIRE FOR KEY IN SECONDS
-spec set_expire_sec(Key :: string(), Timeout :: integer()) ->
  Value :: binary() | {error, binary()}.
set_expire_sec(Key, Timeout) ->
  Query = ["EXPIRE", Key, Timeout],
  cache_query(Query).

%% SET EXPIRE FOR KEY IN MILLISECONDS
-spec set_expire_milisec(Key :: string(), Timeout :: integer()) ->
  Value :: binary() | {error, binary()}.
set_expire_milisec(Key, Timeout) ->
  Query = ["PEXPIRE", Key, Timeout],
  cache_query(Query).

%% SET EXPIRE FOR KEY IN UNIX TIMESTAMP
-spec set_expire_timestamp(Key :: string(), Timeout :: integer()) ->
  Value :: binary() | {error, binary()}.
set_expire_timestamp(Key, Timeout) ->
  Query = ["EXPIREAT", Key, Timeout],
  cache_query(Query).

%% REMOVE EXPIRE TIMEOUT FROM KEY
-spec remove_expire(Key:: string()) ->
  integer() | {error, binary()}.
remove_expire(Key) ->
  Query = ["PERSIST", Key],
  cache_query(Query).

%% GET A KEY, MATCHING BY INPUT PATTERN
-spec find_keys_by_pattern(Pattern :: string()) ->
  Value :: [binary()] | {error, binary()}.
find_keys_by_pattern(Pattern) ->
  Query = ["KEYS", Pattern],
  cache_query(Query).

-spec increment(Key :: string())->
  Value :: [binary()] | {error, binary()}.
increment(Key) ->
  Query = ["INCR", Key],
  cache_query(Query).

decrement(Key) ->
  Query = ["DECR", Key],
  cache_query(Query).


%% TODO: Implement querying for redis
cache_query(Query)->
  ?LOG_DEBUG("Mi zdes' ---- cache_query ~n",[]),
  catch poolboy:transaction(redis_pool, fun(Worker) ->
    gen_server:call(Worker, {equery, Query}, ?WORKER_TIMEOUT),
    ?LOG_DEBUG("Worker ~p~n" , [Worker])
  end).

proplists_to_list([], Acc) ->
  Acc;
proplists_to_list([Elem | Tails], Acc)->
  Res = tuple_to_list(Elem),
  proplists_to_list(Tails, Acc ++ Res).


hset(Key, Value) ->
  cache_query(["HSET", Key, Value]).

hget(Key, Field) ->
  cache_query(["HGET", Key, Field]).

hgetall(Key) ->
  cache_query(["HGETALL", Key]).

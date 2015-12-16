  -module(db_interface).

-define(QUERUES, [
  %%==============================================================================================
  %% INSERTS
  %%==============================================================================================
  {save_payment,
    "INSERT INTO \"test_table42\" (\"amount\", \"currency\", \"account\", \"card_number\", \"status\") "
      "VALUES ($1, $2, $3, $4, $5) RETURNING \"id\""},
  %%==============================================================================================
  %% UPDATES
  %%==============================================================================================
  {update_pay, "UPDATE \"test_table42\".\"transactions\" SET \"prolog_limit\"= $1 WHERE \"id\"= $2"},

  %%==============================================================================================
  %% SELECTS
  %%==============================================================================================
  {select_pay, "SELECT \"account\",\"amount\",\"currency\",\"card_number\",\"status\" from \"test_table42\" WHERE \"account\" = $1"},

  {update_state, "UPDATE \"test_table42\" SET \"status\"= 'paid' WHERE \"account\" = $1   "}

]).
-include("template.hrl").
%% API
-export([execute/2]).

execute(Tag, Data) ->
  {_, QueryStr} = lists:keyfind(Tag, 1, ?QUERUES),
  ?LOG_DEBUG("QueryStr: ~p , Data: ~p~n", [QueryStr, Data]),
  Result = equery(pool1, QueryStr, Data),
  %% @Todo This Parse Reslt
  ?LOG_DEBUG("Result : ~p~n", [Result]),
  Result.

%% Call Poolboy Worder
%% squery(PoolName, SQL) ->
%%   catch poolboy:transaction(PoolName, fun(Worker) ->
%%     gen_server:call(Worker, {squery, SQL}, 10000)
%%   end).

equery(PoolName, SQL, Params) ->
    catch poolboy:transaction(PoolName, fun(Worker) ->
        ?LOG_DEBUG("Params: ~p~n", [Params]),
        ?LOG_DEBUG("Worker: ~p~n", [Worker]),
        gen_server:call(Worker, {equery, SQL, Params}, 10000)
    end).

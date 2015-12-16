%%%-------------------------------------------------------------------
%%% @author user
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. фев 2015 12:36
%%%-------------------------------------------------------------------
-module(rabbit_interface).
-author("user").

-include("template.hrl").

%% API
-export([]).

-export([rb_command/2]).

rb_command(Command, Data) ->
  %{_, QueryStr} = lists:keyfind(Tag, 1, ?QUERUES),
  %?LOG_DEBUG("QueryStr: ~p , Data: ~p~n", [QueryStr, Data]),
  Result = rb_work(rabbit_pool, Command, Data),
  %% @Todo This Parse Reslt
  ?LOG_DEBUG("Result : ~p~n", [Result]),
  Result.

%% Call Poolboy Worder
%% squery(PoolName, SQL) ->
%%   catch poolboy:transaction(PoolName, fun(Worker) ->
%%     gen_server:call(Worker, {squery, SQL}, 10000)
%%   end).

rb_work(PoolName, Command, Msg) ->
  catch poolboy:transaction(PoolName, fun(Worker) ->
    ?LOG_DEBUG("Params: ~p~n", [Command]),
    ?LOG_DEBUG("Worker: ~p~n", [Worker]),
    gen_server:call(Worker, {Command, Msg})
  end).
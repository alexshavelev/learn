%%%-------------------------------------------------------------------
%%% @author user
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. янв 2015 12:29
%%%-------------------------------------------------------------------
-module(learn_paymnt).
-author("user").
-include("template.hrl").

%% API
-behaviour(gen_server).


-export([start_link/0,
  check/6,
  pay/3,
  status/1]).


-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
  terminate/2, code_change/3]).

-record(state, {db=[]}).

-define(SERVER, ?MODULE).


start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init(_Args) ->
  {ok, #state{}}.

check(Order, Card, Amount, Curr, Sign, Ts) ->
   gen_server:call(?MODULE, {check, Order, Card, Amount, Curr, Sign, Ts}).

pay(Order, Sign, Ts) ->
   gen_server:call(?MODULE, {pay, Order, Sign, Ts}).

status(Order) ->
  gen_server:call(?MODULE, {status, Order}).





handle_call({check, Order, Card, Amount, Curr, Sign, Ts}, _From, State) ->
  ?LOG_DEBUG("Incoming req Order: ~p; Card: ~p; ~p~n", [Order, Card, Amount, Curr, Sign, Ts] ),
  Key = <<"748">>,
  Lun = tut_luhn:verify(binary_to_integer(Card)),
  ?LOG_DEBUG("Lun ~p~n",[Lun]),
  {ok, Min} = application:get_env(learn, limit1),
  {ok, Max} = application:get_env(limit2),
  {ok, Currs} = application:get_env(currencies),
  ?LOG_DEBUG("Min ~p~n",[Min]),
  ?LOG_DEBUG("Min ~p~n",[Max]),
  ?LOG_DEBUG("Currs ~p~n",[Currs]),
  Amount2 = binary_to_float(Amount),
  case check_sign:check(Order, Card, Amount, Curr, Ts, Key, Sign) of
    true when Lun =:= true, Amount2 > 0, Amount2 < 100, Curr =:= <<"UAH">> ->
      %ets:insert(payments, {Order, Card, Amount, Curr, Ts, Sign}),
      db_interface:execute(save_payment, [Amount, Curr, Order, Card, <<"new">>]),
      {reply, ok, State};
    false ->
      {reply, invalid_sigh, State};
    _ ->
      {reply, invalid_parametrs, State}
  end;




handle_call({pay, Order, Sign, Ts}, _From, State) ->
  Key = <<"748">>,
  case check_sign:check(Order, Ts, Key, Sign) of
    true ->
          case db_interface:execute(select_pay, [Order]) of
            {ok, _, []} -> {reply, firstly_check, State};
            {ok, _,[_]} -> Te = db_interface:execute(update_state, [Order]),
                           ?LOG_DEBUG("Update ~p~n", [Te]),
                           {reply, ok, State}
          end;
    _ ->
      {reply, invalid_sign, State}
  end;


handle_call({status, Order}, _From, State) ->
  _Record =
    case db_interface:execute(select_pay, [Order]) of
      {ok, _, []} -> {reply, not_payment, State};
      X -> X,
           ?LOG_DEBUG("X ~p~n", [X]),
           {ok, Names, [Values]} = X,
           %_Values2 = tuple_to_list(Values),
           %_Names2 = make(Names),
           ListCort = lists:zip(make(Names), tuple_to_list(Values)),
           ?LOG_DEBUG("ListSort ~p~n", [ListCort]),
           %?LOG_DEBUG("Names2: ~p    Values2: ~p~n" , [Names2, Values2]),
           {reply, ListCort, State}
    end;






handle_call(_Request, _From, State) ->
  io:format("undef ~n"),
  Reply = not_matched_correctly,
  {reply, Reply, State}.



make(X) -> make(X, []).

make([], Result) -> lists:reverse(Result);
make([{_, N, _, _, _, _}|T], Result) -> make(T, [N|Result]).




handle_cast(_Msg, State) ->
  io:format("undef delete ~n"),
  {noreply, State}.

handle_info(_Info, State) ->
  io:format("send mes undef ~n"),
  {noreply, State}.


terminate(_Reason, _State) ->
  ok.


code_change(_OldVsn, State, _Extra) ->
  {ok, State}.





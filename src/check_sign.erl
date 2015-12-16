%%%-------------------------------------------------------------------
%%% @author user
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. янв 2015 12:46
%%%-------------------------------------------------------------------
-module(check_sign).
-author("user").
-include("template.hrl").

%% API
-export([check/7, check/4]).

check(Order, Card, Amount, Currency, Ts, Secret, Sign) ->
   %SignOur2 = Order ++ integer_to_list(Card) ++ float_to_list(Amount) ++ Currency ++ Ts ++ Secret,
   ?LOG_DEBUG("Check sigh ~p~n", [Order, Card, Amount, Currency, Sign, Ts, Secret]),
   SignOur = <<Order/binary, Card/binary,  Amount/binary, Currency/binary, Ts/binary, Secret/binary>>,
   S = base64:encode(SignOur),
   ?LOG_DEBUG("S ~p~n" , [S]),
   ?LOG_DEBUG("Sign ~p~n", [Sign]),
   if Sign =:= S -> true;
     true -> false
   end.

check(Order, Ts, Secret, Sign) ->
  ?LOG_DEBUG("Check sigh ~p~n", [Order, Sign, Ts, Secret]),
  SignOur = <<Order/binary, Ts/binary, Secret/binary>>,
  S = base64:encode(SignOur),
  ?LOG_DEBUG("2S ~p~n" , [S]),
  ?LOG_DEBUG("2Sign ~p~n", [Sign]),
  if Sign =:= S -> true;
    true -> false
  end.

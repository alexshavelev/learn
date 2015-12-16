%%%-------------------------------------------------------------------
%%% @author user
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. янв 2015 12:45
%%%-------------------------------------------------------------------
-module(tut_luhn).
-export([verify/1]).

%%
%% http://en.wikipedia.org/wiki/Luhn_algorithm
%% Алгоритм Лу́на (англ. Luhn algorithm) — алгоритм вычисления контрольной цифры
%% номера пластиковых карт в соответствии со стандартом ISO/IEC 7812
%%
%% tut_luhn:verify(4561261212345467). валидный номер карты
%%
verify(CardNumber) when is_integer(CardNumber) ->
  verify(lists:map(fun(X) -> X - 48 end, integer_to_list(CardNumber)));


verify(CardNumbers) when is_list(CardNumbers) ->
  {_, Sum} = lists:foldr(fun(X, Acc) -> luhn(X, Acc) end, {odd, 0}, CardNumbers),
  if Sum rem 10 == 0 -> true;
    true -> false
  end.


luhn(X, {even, Sum}) ->
  Y = X * 2,
  N = if Y > 9 -> Y - 9;
        true -> Y
      end,
  {odd, Sum + N};

luhn(X, {odd, Sum}) ->
  {even, Sum + X}.


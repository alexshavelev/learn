%% -module(plugins_cardbalance_service).
-export([transform/1]).
transform(Data)->
  FS = [
    {<<"CardPan">>, <<"B.CardPan">>},
    {<<"ExtId">>,   <<"B.ExtId">>},
    {<<"State">>,   <<"B.State">>},
    {<<"Ref">>,     <<"B.Ref">>, <<"undef">>},
%%     {<<"Currency">>,<<"B.Currency">>, <<"undef">>},
    {<<"Sys">>,     <<"B.Sys">>, <<"undef">>},

    {{<<"BaseAccount">>, <<"AccNumber">>},    concat},
    {{<<"BaseAccount">>, <<"Avail">>},        concat},
    {{<<"BaseAccount">>, <<"Remain">>},       concat},
    {{<<"BaseAccount">>, <<"CreditLimit">>},  concat},
    {{<<"BaseAccount">>, <<"Overdraft">>},    concat},
    {{<<"BaseAccount">>, <<"FullRemain">>},   concat},
    {{<<"BaseAccount">>, <<"MinPay">>},       concat},
    {{<<"BaseAccount">>, <<"Currency">>},     concat},

    {{<<"BonusPlus">>, <<"BonusSumm">>},      concat},
    {{<<"BonusPlus">>, <<"Currency">>},       concat}
  ],
  map(FS, Data, [])
.
map([], _Data, Acc) -> Acc;
map([F | FLDS], Data, Acc) -> map(FLDS, Data, Acc ++ [get_value(F, Data)]).

get_value({Field, NewTag, Def}, Data) when erlang:is_binary(Field) andalso erlang:is_binary(NewTag) ->
  V = get(Field, Data, Def),
  {NewTag, V};

get_value({Field, NewTag}, Data) when erlang:is_binary(Field) andalso erlang:is_binary(NewTag) ->
  V = get(Field, Data),
  {NewTag, V};

get_value({{InnTag, TagName}, NewTag}, Data) when erlang:is_binary(InnTag) andalso erlang:is_binary(TagName) andalso erlang:is_binary(NewTag) ->
  InnNDoc = get(InnTag, Data),
  {NewTag, get(TagName, InnNDoc)};

get_value({{InnTag, TagName}, concat}, Data) when erlang:is_binary(InnTag) andalso erlang:is_binary(TagName) ->
  InnNDoc = get(InnTag, Data),
  {<<InnTag/binary, ".", TagName/binary>>, get(TagName, InnNDoc)};

get_value({{InnTag, TagName}, concat, Def}, Data) when erlang:is_binary(InnTag) andalso erlang:is_binary(TagName) ->
  InnNDoc = get(InnTag, Data),
  {<<InnTag/binary, ".", TagName/binary>>, get(TagName, InnNDoc, Def)}.

get(Key, List) ->
  get(Key, List, undefined).


get(Key, [P | Ps], Default) ->
  if erlang:is_atom(P), P =:= Key ->
    true;
    tuple_size(P) >= 1, element(1, P) =:= Key ->
      case P of
        {_, Value} ->
          Value;
        _ ->
          Default
      end;
    true ->
      get(Key, Ps, Default)
  end;
get(_Key, [], Default) ->
%%   erlang:is_binary()
  Default.

%% Error: [{errors,[{28, [82,101,115,116,114,105,99,116,101,100,32,99,97,108,108,58,32, "erlang",58,"is_binary",47,"1"]}]}, {warns,[]}]
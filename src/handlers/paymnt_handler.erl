%%%-------------------------------------------------------------------
%%% @author user
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. янв 2015 12:26
%%%-------------------------------------------------------------------
-module(paymnt_handler).
-author("user").

%% API
-include("template.hrl").
-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

init(_Transport, Req, []) ->
  {ok, Req, undefined}.


handle(Req, State) ->
  ?LOG_DEBUG("request on server ~p~n",[Req]),
  {Method, Req2} = cowboy_req:method(Req),
  ?LOG_DEBUG("Method ~p~n" ,[Method]),
  case Method of
    <<"POST">> ->
      HasBody = cowboy_req:has_body(Req2),
      {ok, Req3} = maybe_echo(Method, HasBody, Req2),
      {ok, Req3, State};
      _ ->
        cowboy_req:reply(405, Req)
  end.



maybe_echo(<<"POST">>, true, Req) ->
  {ok, PostVals, Req2} = cowboy_req:body(Req), %%
  %%?LOG_DEBUG("POST ~p~n", [PostVals]),
  %%Login = proplists:get_value(<<"login">>, PostVals),
  %%?LOG_DEBUG("Login POST ~p~n", [Login]),
  echo(PostVals, Req2);



%% maybe_echo(_, true, Req) ->
%%     true
%%   ;





maybe_echo(<<"POST">>, false, Req) ->
  cowboy_req:reply(400, [], <<"Missing body.">>, Req);

maybe_echo(_, _, Req) ->
  %% Method not allowed.
  cowboy_req:reply(405, Req).





echo(undefined, Req) ->
  cowboy_req:reply(400, [], <<"Missing echo parameter Post.">>, Req);

echo(PostVals, Req) ->
  {Url, Req2} = cowboy_req:path(Req),
  ?LOG_DEBUG("url ~p~n" , [Url]),



  ?LOG_DEBUG("POST ~p~n", [PostVals]),
  PostVals2 = PostVals,
  ?LOG_DEBUG("Get from POST ~p~n", [PostVals2]),
  {Headers, _Req3} = cowboy_req:header(<<"content-type">>, Req2, undefined),
  ?LOG_DEBUG("Headers ~p~n" , [Headers]),
  PostVals3 =
  case Headers of
    <<"application/json">> ->
                jsx:decode(PostVals2);
    <<"application/xml">> ->
                exomler:decode(PostVals2)
  end,
  ?LOG_DEBUG("PostVals3 ~p~n" ,[PostVals3]),
  %PostVals3 = jsx:decode(PostVals2),
  ?LOG_DEBUG("Jifffffy ~p~n" ,[PostVals3]),
  case Headers of
            <<"application/json">> ->
                                  Response =
                                  case Url of
                                    <<"/check">>->
                                                  [{_, Order}, {_, Card}, {_, Amount}, {_, Curr} , {_, Sign}, {_, Ts}] = PostVals3,
                                                  Res = learn_paymnt:check(Order, Card, Amount, Curr, Sign, Ts),
                                %%                   Res2 = {[{check, ok}]},
                                %%                   _Res3 = jsx:encode(Res2),

                                                  %?LOG_DEBUG("JSON ~p~n", [jsx:encode([{check, okok}])]),
                                                  ?LOG_DEBUG("ReSSSSS ~p~n", [Res]),
                                                  if Res =:= ok ->
                                                     jsx:encode([{check, okok}]);
                                                     true -> jsx:encode([{invalid_params, okok}, {chery_lady, true}])
                                                  end;


                                     <<"/pay">> ->
                                                  [{_, Order}, {_, Ts}, {_, Sign}] = PostVals3,
                                                  Res = learn_paymnt:pay(Order, Sign, Ts),
                                                  ?LOG_DEBUG("ReSSSSS ~p~n", [Res]),
                                                  jsx:encode([{pay, Res}]);
                                     <<"/status">> ->
                                                  [{_, Order}] = PostVals3,
                                                  Record = learn_paymnt:status(Order),
                                                  ?LOG_DEBUG("Record: ~p~n",[Record]),
                                                  jsx:encode(Record)

                                    end;

            <<"application/xml">> ->
                                Response =
                                  case Url of
                                    <<"/check">>->
                                      {_, _, [{_, _, [Order]}, {_, _, [Card]}, {_, _, [Amount]}, {_, _ , [Curr]}, {_, _, [Sign]}, {_, _, [Ts]}]} = PostVals3,
                                      Res = learn_paymnt:check(Order, Card, Amount, Curr, Sign, Ts),
                                      %%                   Res2 = {[{check, ok}]},
                                      %%                   _Res3 = jsx:encode(Res2),

                                      %?LOG_DEBUG("JSON ~p~n", [jsx:encode([{check, okok}])]),
                                      ?LOG_DEBUG("ReSSSSS ~p~n", [Res]),
                                      if Res =:= ok ->
                                        exomler:encode_document({xml, '1.0', utf8, {<<"test">>, [{<<"check">>, <<"ok">>}], []}});
                                        %%As example
                                        %%exomler:encode_document({xml, '1.0', utf8,  {<<"selectPA">>,[{<<"xmlns:xsi">>,<<"http://www.w3.org/2001/XMLSchema-instance">>},{<<"bank">>,<<"PB">>},{<<"lang">>,<<"ru">>},{<<"pointType">>,<<"WKASS">>},{<<"companyID">>,<<"1866056">>}],[{<<"property">>,[{<<"xsi:type">>,<<"SimpleProperty">>},{<<"alias">>,<<"ls">>},{<<"value">>,<<"243014">>}],[]}]}});
                                        true -> exomler:encode_document({xml, '1.0', utf8 , {<<"test">>, [{<<"check">>, <<"invalid_parametrs">>}, {<<"chery_lady">>, <<"true">>}], []}})
                                      end;


                                    <<"/pay">> ->
                                      {_, _, [{_, _, [Order]}, {_, _, [Ts]}, {_, _, [Sign]}]}= PostVals3,
                                      Res = learn_paymnt:pay(Order, Sign, Ts),
                                      ?LOG_DEBUG("ReSSSSS ~p~n", [Res]),
                                      %jsx:encode([{pay, okok}]),
                                      if Res =:= ok ->
                                            exomler:encode_document({xml, '1.0', utf8, {<<"pay">>, [{<<"pay">>, <<"ok">>}], []}});
                                            true ->  exomler:encode_document({xml, '1.0', utf8 , {<<"test">>, [{<<"check">>, <<"invalid_parametrs">>}, {<<"chery_lady">>, <<"true">>}], []}})
                                      end;

                                    <<"/status">> ->
                                      {_, _, [{_, _, [Order]}]}= PostVals3,
                                      Res = learn_paymnt:status(Order),
                                      ?LOG_DEBUG("Res ~p~n", [Res]),
                                      exomler:encode_document({xml, '1.0', utf8, {<<"pay">>, Res, []}})
                                  end

  end,
  cowboy_req:reply(200, [
    {<<"content-type">>, <<"text/plain; charset=utf-8">>}
  ], Response, Req).



terminate(_Reason, _Req, _State) ->
  ok.
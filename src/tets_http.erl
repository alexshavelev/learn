%%%-------------------------------------------------------------------
%%% @author user
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. фев 2015 16:41
%%%-------------------------------------------------------------------
-module(tets_http).
-author("user").

%% API
-export([proc/0]).
-include("conv_plugins.hrl").

%% req(Method, Url, Headers, ContType, Body, HttpOpts)
%%   when Method == post orelse Method == put orelse Method == delete ->
%%   HttpClOpts = [{sync, true},{body_format,binary}],
%%   Resp = httpc:request(Method, {eu_types:to_list(Url), Headers, ContType, Body}, HttpOpts, HttpClOpts),
%%   minimize_resp(Resp).
%%
%% req(get, Url, Headers, HttpOpts) ->
%%   HttpClOpts = [{sync, true},{body_format,binary}],
%%   Resp = httpc:request(get, {eu_types:to_list(Url), Headers}, HttpOpts, HttpClOpts),
%%   minimize_resp(Resp).


-define(Url, "https://api.privatbank.ua/p24api/pubinfo?json&exchange&coursid=5").


proc() ->
  case http_requester:req(get, ?Url, [], [{timeout, 30000}]) of
    {ok, 200, RespBody} ->
      prepeare_response(RespBody);
    {error, ErCode, ErrResp} ->
      ?LOG_WARNING("{ ~p } Error response ~p from a server ~p", [?MODULE, ErCode, ErrResp]),
      ?ThrowSimpleException(<<"response code from external server ", (eu_types:to_binary(ErCode))/binary, " Resp body: ", (eu_types:to_binary(ErrResp))/binary>>)
  end.



prepeare_response(RespBody)   ->
  case jsx:is_json(RespBody) of
    true -> jsx:decode(RespBody),
            ?LOG_DEBUG("Http Res ~p~n", [RespBody]);
    _ -> ?ThrowSimpleException(3001, <<"not a json response:::  ", (eu_types:to_binary(RespBody))/binary>>)
  end.
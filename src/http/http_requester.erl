%%%-------------------------------------------------------------------
%%% @author user
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. фев 2015 16:41
%%%-------------------------------------------------------------------
-module(http_requester).
-author("user").

%% API


-export([
  req/6, 	%% Post, Put, Delete Only
  req/4 	%% Get Only
]).

req(Method, Url, Headers, ContType, Body, HttpOpts)
  when Method == post orelse Method == put orelse Method == delete ->
  HttpClOpts = [{sync, true},{body_format,binary}],
  Resp = httpc:request(Method, {eu_types:to_list(Url), Headers, ContType, Body}, HttpOpts, HttpClOpts),
  minimize_resp(Resp).

req(get, Url, Headers, HttpOpts) ->
  HttpClOpts = [{sync, true},{body_format,binary}],
  Resp = httpc:request(get, {eu_types:to_list(Url), Headers}, HttpOpts, HttpClOpts),
  minimize_resp(Resp).

minimize_resp(Resp) ->
  case Resp of
    {ok, {{_NewVrsn, 200, _}, _Headers, RespBody}} ->
      {ok, 200, RespBody};
    {ok, {{_NewVrsn, HttpCode, _}, _Headers, RespBody}} ->
      {error, HttpCode, RespBody};
    Any -> Any
  end.

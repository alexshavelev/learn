%%%-------------------------------------------------------------------
%%% @author user
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. янв 2015 19:12
%%%-------------------------------------------------------------------
-module(notfound_handler).
-author("user").
-include("template.hrl").

%% API
-export([
  init/3,
  handle/2,
  terminate/3
]).

init({tcp, http}, Req, _Opts) ->
  {ok, Req, undefined_state}.

handle(Req, State) ->
  %%?LOG_DEBUG(Req),
  Body = <<"<h1>404 Page Not Found</h1>">>,
  {ok, Req2} = cowboy_req:reply(404, [], Body, Req),
  %%?LOG_DEBUG(Req2),
  {ok, Req2, State}.

terminate(_Reason, _Req, _State) ->
  ok.
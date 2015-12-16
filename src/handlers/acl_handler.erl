%%%-------------------------------------------------------------------
%%% @author user
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. янв 2015 18:04
%%%-------------------------------------------------------------------
-module(acl_handler).
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
    <<"GET">> ->
      {PathInfo, Req3} = cowboy_req:path_info(Req2),
      ?LOG_INFO("Echo ~p~n" , [PathInfo]),
      {ok, Req4} = echo(Method, PathInfo, Req3),
      {ok, Req4, State};
    _ ->
      cowboy_req:reply(405, Req)
  end.


maybe_echo(<<"POST">>, true, Req) ->
  {ok, PostVals, Req2} = cowboy_req:body_qs(Req), %%
  %%?LOG_DEBUG("POST ~p~n", [PostVals]),
  %%Login = proplists:get_value(<<"login">>, PostVals),
  %%?LOG_DEBUG("Login POST ~p~n", [Login]),
  echo(PostVals, Req2);

maybe_echo(<<"POST">>, false, Req) ->
  cowboy_req:reply(400, [], <<"Missing body.">>, Req);


maybe_echo(_, _, Req) ->
  %% Method not allowed.
  cowboy_req:reply(405, Req).


%%% for processing GET
echo(<<"GET">>, undefined, Req) ->
  ?LOG_INFO("Get respo undef ~p~n", [cowboy_req:reply(400, [], <<"Missing echo parameter. GET">>, Req)]);

echo(<<"GET">>, PathInfo, Req) ->
  ?LOG_DEBUG("Mi zdes' ~p~n", [PathInfo]),
  case PathInfo of
    [<<"authorize">>] ->
          ?LOG_DEBUG("Auth ~p~n", [PathInfo]),
          {Login, Req2} = cowboy_req:qs_val(<<"login">>, Req),
          {Pass, Req3} = cowboy_req:qs_val(<<"pass">>, Req2),
          Res =
          case learn_achl2:authorize(binary_to_list(Login), binary_to_list(Pass)) of
              no_user ->
                    <<"no_user">>;
              invalid_login_or_password ->
                    <<"inv_log_or_pass">>;
              access ->
                    <<"access">>;
              _ ->
                  <<"error">>
          end,
          ?LOG_DEBUG("Response, ~p~n" , [cowboy_req:reply(200, [
          {<<"content-type">>, <<"text/plain; charset=utf-8">>}
          ], Res, Req3)]);
    [<<"add">>] ->
          ?LOG_DEBUG("Add ~p~n", [PathInfo]),
          {Login, Req2} = cowboy_req:qs_val(<<"login">>, Req),
          %%Login1 = binary_to_list(Login),
          ?LOG_DEBUG("~p~n", [Login]),
          {Pass, Req3} = cowboy_req:qs_val(<<"pass">>, Req2),
          {Role, Req4} = cowboy_req:qs_val(<<"role">>, Req3),
          Res=
          case learn_achl2:add(binary_to_list(Login), binary_to_list(Pass), binary_to_list(Role)) of
              registered ->
                    <<"registered">>;
              invalid_params ->
                    <<"invalid_params">>;
              Res_ ->
                ?LOG_DEBUG("err ~p~n", [Res_]),
                <<"error">>
          end,
          ?LOG_DEBUG("Response, ~p~n" , [cowboy_req:reply(200, [
            {<<"content-type">>, <<"text/plain; charset=utf-8">>}
          ], Res, Req4)]);

    [<<"change_role">>] ->
          ?LOG_DEBUG("Change ~p~n", [PathInfo]),
          {Login, Req2} = cowboy_req:qs_val(<<"login">>, Req),
          ?LOG_DEBUG("~p~n", [Login]),
          {Pass, Req3} = cowboy_req:qs_val(<<"pass">>, Req2),
          {NewRole, Req4} = cowboy_req:qs_val(<<"newrole">>, Req3),
          Res =
          case learn_achl2:change_role(binary_to_list(Login), binary_to_list(Pass), binary_to_list(NewRole)) of
            role_changed ->
                <<"role_changed">>;
            invalid_login_or_password ->
                <<"invalid_login_or_password">>;
            _ ->
                <<"error occupied">>
          end,
          ?LOG_DEBUG("Response, ~p~n" , [cowboy_req:reply(200, [
            {<<"content-type">>, <<"text/plain; charset=utf-8">>}
          ], Res, Req4)]);

    [<<"get_msg">>] ->
          ?LOG_DEBUG("Get Messages ~p~n", [PathInfo]),
          {Login, Req2} = cowboy_req:qs_val(<<"login">>, Req),
          {Pass, Req3} = cowboy_req:qs_val(<<"pass">>, Req2),
          Res =
          case learn_achl2:get_msg(binary_to_list(Login), binary_to_list(Pass)) of
            no_account ->
                <<"no_account">>;
            invalid_login_or_password ->
              <<"invalid_login_or_password">>;
            Message ->
               %%list_to_binary(Message),
               ?LOG_DEBUG("Message ~p~n", [Message]),
              list_to_binary(Message)
          end,
          ?LOG_DEBUG("Response, ~p~n" , [cowboy_req:reply(200, [
            {<<"content-type">>, <<"text/plain; charset=utf-8">>}
          ], Res, Req3)]);


    [<<"send_msg">>] ->
          ?LOG_DEBUG("Send Messages ~p~n", [PathInfo]),
          {Login, Req2} = cowboy_req:qs_val(<<"login">>, Req),
          {Message, Req3} = cowboy_req:qs_val(<<"message">>, Req2),
          Res =
          case learn_achl2:send_msg(binary_to_list(Login), binary_to_list(Message)) of
            {send_msg, _, _} ->
                <<"message send">>;
            _ ->
                <<"error">>
          end,
          ?LOG_DEBUG("Response, ~p~n" , [cowboy_req:reply(200, [
            {<<"content-type">>, <<"text/plain; charset=utf-8">>}
          ], Res, Req3)]);

    [_] ->
          ?LOG_DEBUG("Other variant ~p~n", [PathInfo]),
          ?LOG_DEBUG("Response, ~p~n" , [cowboy_req:reply(200, [
          {<<"content-type">>, <<"text/plain; charset=utf-8">>}
          ], <<"undefinded req, check docs">>, Req)])
   end;


echo(_, _, Req) ->
  %% Method not allowed.
  cowboy_req:reply(405, Req).

%%% for POST
echo(undefined, Req) ->
  cowboy_req:reply(400, [], <<"Missing echo parameter Post.">>, Req);
echo(PostVals, Req) ->
  ?LOG_DEBUG("POST ~p~n", [PostVals]),
  Login = proplists:get_value(<<"login">>, PostVals),
  ?LOG_DEBUG("Login POST ~p~n", [Login]),
  Pass = proplists:get_value(<<"pass">>, PostVals),
  Role = proplists:get_value(<<"role">>, PostVals),

  Res=
    case learn_achl2:add(binary_to_list(Login), binary_to_list(Pass), binary_to_list(Role)) of
      registered ->
        <<"registered">>;
      invalid_params ->
        <<"invalid_params">>;
      Res_ ->
        ?LOG_DEBUG("err ~p~n", [Res_]),
        <<"error">>
    end,
  cowboy_req:reply(200, [
    {<<"content-type">>, <<"text/plain; charset=utf-8">>}
  ], Res, Req).

terminate(_Reason, _Req, _State) ->
  ok.
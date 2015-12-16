-module(plugins_rabbitmq).
-author("Kletsko Vitali <v.kletsko@gmail.com>").

-export([process/1, test/0, test/1]).

-include_lib("../deps/amqp_client/include/amqp_client.hrl").

-include("conv_plugins.hrl").

process([ConvObj | _]) when is_record(ConvObj, conveyor_api_request_event)->
  Extra = ConvObj#conveyor_api_request_event.extra,
  Result = do_process(Extra),
  eu_conveyor:reqObj2respObj(ConvObj, Result).

do_process(Data) ->
  ?LOG_INFO("{RabbitMq} in Params: ~p~n", [Data]),
  Oper = proplists:get_value(<<"oper">>, Data),
  Checked = case check_req(Oper, Data) of
    {ok, Par} ->
      ?LOG_INFO("{RabbitMq} Servise: ~p~n", [Par]),
      Par;
    {error, Rrr} ->
      ?LOG_WARNING("{RabbitMq} Bad Inc Params Reason: ~p~n", [Rrr]),
      ?ThrowSimpleException(1000, Rrr)
  end,
  {ActionRecord, Opts}= case build_action_record(Oper, Checked) of
    {ok, Record, AddData} -> {Record, AddData};
    {error, Reason} ->
      ?ThrowSimpleException(1000, Reason)
  end,
  case action(Oper, ActionRecord, Opts) of
    {ok, Resp} ->
      ?LOG_INFO("{RabbitMq} Action Resp: ~p~n", [Resp]),
      ?wrapp_succes_response(?MODULE, Resp);
    {error, ErrDesc} ->
      ?ThrowSimpleException(4001, ErrDesc)
  end.

check_req(<<"getMessageCount">>, Data) ->
  case catch request_validator:get_fields([<<"connectKey">>], Data) of
    List when is_list(List) -> {ok, List};
    Any -> Any
  end;
check_req(<<"init">>, Data) ->
  Fields = [
    <<"username">>,
    <<"password">>,
    <<"host">>,
    <<"port">>,
    {<<"queue">>,           optional},
    {<<"virtual_host">>,    optional},
    {<<"channel_max">>,     optional},
    {<<"frame_max">>,       optional},
    {<<"heartbeat">>,       optional},
    {<<"ssl_options">>,     optional},
    {<<"auth_mechanisms">>, optional},
    {<<"client_properties">>,optional}
  ],
  case catch request_validator:get_fields(Fields, Data) of
    List when is_list(List) -> {ok, List};
    Any -> Any
  end.

action(<<"init">>, ParamsNetwork, Data) when is_record(ParamsNetwork, amqp_params_network) ->
  ?LOG_DEBUG("ConnRec: ~p~n", [ParamsNetwork]),
  case amqp_connection:start(ParamsNetwork) of
    {ok, Conn} ->
      case amqp_connection:open_channel(Conn) of
        {ok, Channel} ->
          ?LOG_DEBUG("Conn Log: ~p~n", [{Conn, Channel}]),
          Ref = util:rand_gen(20),
          Queue = proplists:get_value(<<"queue">>, Data),
          true = ets:insert(?RABBIT_CONN, {Ref, Conn, Channel, Queue, ts()}),
          {ok, [{<<"connectKey">>, Ref}]};
        Any ->
          ?LOG_WARNING("{RabbitMq} Error Declare Channel Reason: ~p~n", [Any]),
          {error, <<"Declare Channel Error">>}
      end;
    Any ->
      ?LOG_WARNING("{RabbitMq} Error Open Connect Reason: ~p~n", [Any]),
      {error, <<"Connect to RabbitMq Error">>}
  end;
action(<<"getMessageCount">>, Declare, Data) when is_record(Declare, 'queue.declare') ->
  ?LOG_DEBUG("DeclareRec: ~p~n", [Declare]),
  {ConnectKey, Conn, Channel, Queue, _OldTs} = Data,
  case  amqp_channel:call(Channel, Declare) of
    #'queue.declare_ok'{message_count = MessageCount} ->
      true = ets:insert(?RABBIT_CONN, {ConnectKey, Conn, Channel, Queue, ts()}),
      {ok, [{<<"messageCount">>, MessageCount}]};
    Any ->
      ?LOG_WARNING("{RabbitMq} Error getMessageCount Reason: ~p~n", [Any]),
      {error, <<"getMessageCount Error, Need reconnect">>}
  end.

%% Commons
build_action_record(<<"init">>, Data) ->
  build_connect_record(Data);
build_action_record(<<"getMessageCount">>, Data) ->
  build_declare_record(Data).

%% Declare Record
build_declare_record(Params) ->
  {_, ConnectKey} = lists:keyfind(<<"connectKey">>, 1, Params),
  case ets:lookup(?RABBIT_CONN, ConnectKey) of
    [{ConnectKey, _Conn, _Channel, Queue, _OldTs} = ConnData] ->
      {ok, #'queue.declare'{queue = Queue, passive = true}, ConnData};
    [] ->
      {error, <<"Connect Undefined">>}
  end.

%% Connect Record
build_connect_record(Params) ->
  Fields = [{atom_to_binary(F, utf8), F} || F <- record_info(fields, amqp_params_network)],
  ?LOG_DEBUG("FIELDS: ~p~n", [{Fields, Params}]),
  build_connect_record(Params, Fields, #amqp_params_network{}).

%% set required fields
build_connect_record(Params, [], Rec) -> {ok, Rec, Params};
build_connect_record(Params, [{Key, username}|T], Rec) ->
  {_, Val} = lists:keyfind(Key, 1, Params),
  build_connect_record(Params, T, Rec#amqp_params_network{username = Val});
build_connect_record(Params, [{Key, password}|T], Rec) ->
  {_, Val} = lists:keyfind(Key, 1, Params),
  build_connect_record(Params, T, Rec#amqp_params_network{password = Val});
build_connect_record(Params, [{Key, host}|T], Rec) ->
  {_, Val} = lists:keyfind(Key, 1, Params),
  build_connect_record(Params, T, Rec#amqp_params_network{host = eu_types:to_list(Val)});
build_connect_record(Params, [{Key, port}|T], Rec) ->
  {_, Val} = lists:keyfind(Key, 1, Params),
  build_connect_record(Params, T, Rec#amqp_params_network{port = eu_types:to_integer(Val)});
%% set optional fields
build_connect_record(Params, [{Key, virtual_host}|T], Rec) ->
  case lists:keyfind(Key, 1, Params) of
    {_, Val} ->
      build_connect_record(Params, T, Rec#amqp_params_network{virtual_host = Val});
    false ->
      build_connect_record(Params, T, Rec)
  end;
build_connect_record(Params, [{Key, channel_max}|T], Rec) ->
  case lists:keyfind(Key, 1, Params) of
    {_, Val} ->
      build_connect_record(Params, T, Rec#amqp_params_network{channel_max = eu_types:to_integer(Val)});
    false ->
      build_connect_record(Params, T, Rec)
  end;
build_connect_record(Params, [{Key, frame_max}|T], Rec) ->
  case lists:keyfind(Key, 1, Params) of
    {_, Val} ->
      build_connect_record(Params, T, Rec#amqp_params_network{frame_max = eu_types:to_integer(Val)});
    false ->
      build_connect_record(Params, T, Rec)
  end;
build_connect_record(Params, [{Key, heartbeat}|T], Rec) ->
  case lists:keyfind(Key, 1, Params) of
    {_, Val} ->
      build_connect_record(Params, T, Rec#amqp_params_network{heartbeat = eu_types:to_integer(Val)}); %% ??
    false ->
      build_connect_record(Params, T, Rec)
  end;
build_connect_record(Params, [{Key, ssl_options}|T], Rec) ->
  case lists:keyfind(Key, 1, Params) of
    {_, Val} ->
      build_connect_record(Params, T, Rec#amqp_params_network{ssl_options = Val});
    false ->
      build_connect_record(Params, T, Rec)
  end;
build_connect_record(Params, [{Key, auth_mechanisms}|T], Rec) ->
  case lists:keyfind(Key, 1, Params) of
    {_, Val} ->
      build_connect_record(Params, T, Rec#amqp_params_network{auth_mechanisms = Val});
    false ->
      build_connect_record(Params, T, Rec)
  end;
build_connect_record(Params, [{Key, client_properties}|T], Rec) ->
  case lists:keyfind(Key, 1, Params) of
    {_, Val} ->
      build_connect_record(Params, T, Rec#amqp_params_network{client_properties = Val});
    false ->
      build_connect_record(Params, T, Rec)
  end;
build_connect_record(Params, [_|T], Rec) ->
  build_connect_record(Params, T, Rec).

ts() ->
  calendar:datetime_to_gregorian_seconds(calendar:local_time()).

%% tests
%% plugins_rabbitmq:test().
test() ->
  Url = "http://localhost:8008/commons/rabbitmq",
  JsonReq = build_req(),
  io:format("{RabbitMq} test Request: ~p~n", [JsonReq]),
  Res = conv_http:req(post, Url, ?DEF_HEADERS, ?CONT_TYPE_JSON, JsonReq, [{timeout, 30000}]),
  io:format("Plugin Result process: ~p~n", [Res]).

%% plugins_rabbitmq:test().
test(ConnKey) ->
  Url = "http://localhost:8008/commons/rabbitmq",
  JsonReq = build_req2(ConnKey),
  io:format("{RabbitMq} test Request: ~p~n", [JsonReq]),
  Res = conv_http:req(post, Url, ?DEF_HEADERS, ?CONT_TYPE_JSON, JsonReq, [{timeout, 30000}]),
  io:format("Plugin Result process: ~p~n", [Res]).

build_req() ->
  Par = [{<<"ops">>,[[
    {<<"ref">>,     <<"test_statements">>},
    {<<"type">>,    <<"list">>},
    {<<"obj_id">>,  <<"clientProducts">>},
    {<<"conv_id">>, <<"111">>},
    {<<"node_id">>, <<"53b65f891a8a387b943aed4d">>},
    {<<"data">>,    []},
    {<<"extra">>,[
      {<<"oper">>,        <<"init">>},
      {<<"queue">>,       <<"p48PayQueue">>},
      {<<"username">>,    <<"dn060389drv">>},
      {<<"password">>,    <<"dn060389drv">>},
      {<<"host">>,        <<"10.1.108.165">>},
      {<<"port">>,        <<"5672">>},
      {<<"virtual_host">>,<<"/p48">>}
    ]}
  ]]}],
  jsx:encode(Par).

build_req2(ConnKey) ->
  Par = [{<<"ops">>,[[
    {<<"ref">>,     <<"test_statements">>},
    {<<"type">>,    <<"list">>},
    {<<"obj_id">>,  <<"clientProducts">>},
    {<<"conv_id">>, <<"111">>},
    {<<"node_id">>, <<"53b65f891a8a387b943aed4d">>},
    {<<"data">>,    []},
    {<<"extra">>,[
      {<<"oper">>,      <<"getMessageCount">>},
      {<<"connectKey">>,ConnKey}
    ]}
  ]]}],
  jsx:encode(Par).

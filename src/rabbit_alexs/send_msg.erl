%%%-------------------------------------------------------------------
%%% @author user
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. фев 2015 11:31
%%%-------------------------------------------------------------------
-module(send_msg).
-author("user").

%% API
-export([main/1]).

-include_lib("amqp_client/include/amqp_client.hrl").

main(Msg) ->
  {ok, Connection} =
    amqp_connection:start(#amqp_params_network{host = "localhost", username = <<"admin">>, password = <<"password">>}),
  {ok, Channel} = amqp_connection:open_channel(Connection),

  amqp_channel:call(Channel, #'queue.declare'{queue = <<"alex_test">>}),

  amqp_channel:cast(Channel,
    #'basic.publish'{
      exchange = <<"">>,
      routing_key = <<"alex_test">>},
    #amqp_msg{payload = eu_types:to_binary(Msg)}),
  io:format(" [x] Sent ~p ~n", [Msg]),
  ok = amqp_channel:close(Channel),
  ok = amqp_connection:close(Connection),
  ok.

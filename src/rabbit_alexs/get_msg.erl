%%%-------------------------------------------------------------------
%%% @author user
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. фев 2015 11:37
%%%-------------------------------------------------------------------
-module(get_msg).
-author("user").

%% API
-export([main/1]).

-include_lib("amqp_client/include/amqp_client.hrl").

main(_) ->
  {ok, Connection} =
    amqp_connection:start(#amqp_params_network{host = "localhost", username = <<"admin">>, password = <<"password">>}),
  {ok, Channel} = amqp_connection:open_channel(Connection),

  amqp_channel:call(Channel, #'queue.declare'{queue = <<"alex_test">>}),
  io:format(" [*] Waiting for messages. To exit press CTRL+C~n"),

  amqp_channel:subscribe(Channel, #'basic.consume'{queue = <<"alex_test">>,
    no_ack = true}, self()),
  receive
    #'basic.consume_ok'{} -> ok
  end,
  loop(Channel).


loop(Channel) ->
  receive
    {#'basic.deliver'{}, #amqp_msg{payload = Body}} ->
      io:format(" [x] Received ~p~n", [Body]),
      loop(Channel)
  end.

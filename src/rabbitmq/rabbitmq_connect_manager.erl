-module(rabbitmq_connect_manager).
-author("Vitaly Kletkso <v.kletsko@gmail.com>").

-behaviour(gen_server).

-include("conv_plugins.hrl").

-export([start_link/0, init/1]). 
    
-export([ 
        handle_call/3, 
        handle_cast/2, 
        handle_info/2, 
        terminate/2, 
        code_change/3]).

-define(SEC, 1000).
-define(INTERVAL, 5000).

-record(state, {timer, interval, close_after}).

%% Server implementation, a.k.a.: callbacks
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    {ok, Conf} = application:get_env(learn, rabbitmq_conf),
    {_, Interval} = lists:keyfind(interval, 1, Conf),
    {_, CloseAfter} = lists:keyfind(close_after, 1, Conf),
    TimerSess = erlang:send_after(1000, self(), check_connects),
    ?LOG_DEBUG("{RabbitMq Connect Manager} Started Pid: ~p~n", [self()]),
    {ok, #state{timer  = TimerSess, interval = Interval, close_after = CloseAfter}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(check_connects, S) ->
    erlang:cancel_timer(S#state.timer),
    Now = calendar:datetime_to_gregorian_seconds(calendar:local_time()),
    check_connects(Now - S#state.close_after),
    NewTimer = erlang:send_after(S#state.interval + 200, self(), check_connects),
    {noreply, S#state{timer = NewTimer}};
handle_info(Info, State) ->
    ?LOG_WARNING("{RabbitMq Connect Manager} any msg: ~p~n", [Info]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%% common functions
check_connects(OldTs) ->
  check_connects(ets:tab2list(?RABBIT_CONN), OldTs).

check_connects([], _OldTs) -> ok;
check_connects([{ConnectKey, Conn, Channel, _Queue, Ts}|T], OldTs) ->
  case check_old(OldTs, Ts) of
    true ->
      true = ets:delete(?RABBIT_CONN, ConnectKey),
      amqp_channel:close(Channel),
      amqp_connection:close(Conn);
    false -> skip
  end,
  check_connects(T, OldTs).

check_old(OldTs, Ts) ->
  Ts < OldTs.

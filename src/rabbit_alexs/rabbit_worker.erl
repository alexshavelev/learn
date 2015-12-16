%%%-------------------------------------------------------------------
%%% @author user
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. фев 2015 12:27
%%%-------------------------------------------------------------------
-module(rabbit_worker).
-author("user").

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-include("template.hrl").

-include_lib("amqp_client/include/amqp_client.hrl").

-behaviour(gen_server).

-record(state, {config, connection_pid}).


-spec(start_link(term()) ->
  {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link(Config) ->
  gen_server:start(?MODULE, [Config], []).



-spec(init(Args :: term()) ->
  {ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term()} | ignore).
init([Config]) ->
  process_flag(trap_exit, true),
  self() ! connect,
  {ok, #state{config = Config}}.


-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
    State :: #state{}) ->
  {reply, Reply :: term(), NewState :: #state{}} |
  {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_call({send, Msg}, _From, #state{connection_pid = Conn}=State) ->
  ?LOG_DEBUG("Tuttttt   --- Conn: ~p~n" , [Conn]),
  {ok, Channel} = amqp_connection:open_channel(Conn),
  amqp_channel:call(Channel, #'queue.declare'{queue = <<"alex_test">>}),
  amqp_channel:cast(Channel,
    #'basic.publish'{
      exchange = <<"">>,
      routing_key = <<"alex_test">>},
    #amqp_msg{payload = eu_types:to_binary(Msg)}),
  ?LOG_DEBUG("Mi zdes' 1 ~n",[]),
  %{reply, pgsql:squery(Conn, Sql), State};
  {reply, ok, State};

handle_call({get, _}, _From, #state{connection_pid = Conn}=State) ->
  ?LOG_DEBUG("Mi zdes' 2 ~n",[]),
  ?LOG_DEBUG("Conn ~p~n", [Conn]),


  {ok, Channel} = amqp_connection:open_channel(Conn),

  amqp_channel:call(Channel, #'queue.declare'{queue = <<"alex_test">>}),
  io:format(" [*] Waiting for messages. To exit press CTRL+C~n"),

  amqp_channel:subscribe(Channel, #'basic.consume'{queue = <<"alex_test">>,
    no_ack = true}, self()),
  receive
    #'basic.consume_ok'{} -> ok
  end,
  Res = loop(Channel),
  {reply, Res, State};


handle_call(_Request, _From, State) ->
  ?LOG_DEBUG("Mi zdes' 3 ~n",[]),
  {reply, ok, State}.



loop(Channel) ->
  receive
    {#'basic.deliver'{}, #amqp_msg{payload = Body}} ->
      io:format(" [x] Received ~p~n", [Body]),
      Body,
      loop(Channel)
  end.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_cast(Request :: term(), State :: #state{}) ->
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_cast(_Request, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
-spec(handle_info(Info :: timeout() | term(), State :: #state{}) ->
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_info(connect, State) ->
  NewState = connect(State),
  {noreply, NewState};
handle_info({'DOWN', Ref, _, Pid, Reason}, State) ->
  % erlang:demonitor(Ref),
  ?LOG_INFO("PSQL Pool Porcess receive 'Down' ref ~p with Reason: ~p~n", [Ref, {Pid, Reason}]),
  {stop, normal, State};
handle_info({'EXIT', _MonitorRef, Reason}, State)->
  {stop, Reason, State};
handle_info(reconnection_limit, State)->
  {stop, normal, State};
handle_info(_Info, State) ->
  ?LOG_INFO("undefined info in ~p with message ~p", [self(), _Info]),
  {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: #state{}) -> term()).
terminate(normal, State) ->
  catch pgsql:close(State#state.connection_pid),
  ok;
terminate(Reason, State) ->
  ?LOG_WARNING("~p Worker with Pid: ~p Terminated wtih reason ~p", [psql, self(), Reason]),
  catch pgsql:close(State#state.connection_pid),
  ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
    Extra :: term()) ->
  {ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
connect(State) ->

    case amqp_connection:start(#amqp_params_network{host = "localhost", username = <<"admin">>, password = <<"password">>}) of
      {ok, Connection} ->
             erlang:monitor(process, Connection),
             State#state{connection_pid = Connection};
      _ -> error,
           State
    end.




%%   Hostname = proplists:get_value(hostname, State#state.config),
%%   Database = proplists:get_value(database, State#state.config),
%%   Username = proplists:get_value(username, State#state.config),
%%   Password = proplists:get_value(password, State#state.config),
%%   case pgsql:connect(Hostname, Username, Password, [{database, Database}]) of
%%     {ok, Conn} ->
%%       io:format("~p Worker: connected with Pid: ~p", [psql, Conn]),
%%       erlang:monitor(process, Conn),
%%       State#state{connection_pid = Conn};
%%     Error ->
%%       io:format("~p Worker ~p: cannot connect with message: ~p~n", [psql, self(), Error]),
%%       State


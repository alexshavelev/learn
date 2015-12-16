%%%-------------------------------------------------------------------
%%% @author Vitali Kletsko
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. июн 2014 09:35
%%%-------------------------------------------------------------------
-module(redis_cache_worker).


%%%%%%%%%%%%%%%%%%%%%%%%%% MINE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% -author("Vitali Kletsko <v.kletsko@gmail.com>").
%%
%% -behaviour(gen_server).
%%
%% %% API
%% -export([start_link/1]).
%%
%% %% gen_server callbacks
%% -export([init/1,
%%   handle_call/3,
%%   handle_cast/2,
%%   handle_info/2,
%%   terminate/2,
%%   code_change/3]).
%%
%% -define(DEFAULT_RECONNECT_TIMEOUT, 4000).
%%
%% -define(DEF_HEALTH_CHECK_TIMEOUT, 60 * 1000).
%% -define(RECONNECTION_LIMIT, 5).
%% -define(SERVER, ?MODULE).
%%
%%
%% -include("template.hrl").
%%
%% -record(state, {config, connection_pid, reconnect_timeout = ?DEFAULT_RECONNECT_TIMEOUT, reconnect_counter = 0, health_check_tref}).
%%
%% %%%===================================================================
%% %%% API
%% %%%===================================================================
%%
%% %%--------------------------------------------------------------------
%% %% @doc
%% %% Starts the server
%% %%
%% %% @end
%% %%--------------------------------------------------------------------
%% -spec(start_link(term()) ->
%%   {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
%% start_link(Config) ->
%%   gen_server:start_link(?MODULE, [Config], []).
%%
%% %% start_link() ->
%% %%   gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
%%
%% %%%===================================================================
%% %%% gen_server callbacks
%% %%%===================================================================
%%
%% %%--------------------------------------------------------------------
%% %% @private
%% %% @doc
%% %% Initializes the server
%% %%
%% %% @spec init(Args) -> {ok, State} |
%% %%                     {ok, State, Timeout} |
%% %%                     ignore |
%% %%                     {stop, Reason}
%% %% @end
%% %%--------------------------------------------------------------------
%% -spec(init(Args :: term()) ->
%%   {ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
%%   {stop, Reason :: term()} | ignore).
%% init([Config]) ->
%%   process_flag(trap_exit, true),
%%   self() ! connect,
%%   {ok, #state{config = Config}}.
%%
%% %%--------------------------------------------------------------------
%% %% @private
%% %% @doc
%% %% Handling call messages
%% %%
%% %% @end
%% %%--------------------------------------------------------------------
%% -spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
%%     State :: #state{}) ->
%%   {reply, Reply :: term(), NewState :: #state{}} |
%%   {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
%%   {noreply, NewState :: #state{}} |
%%   {noreply, NewState :: #state{}, timeout() | hibernate} |
%%   {stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
%%   {stop, Reason :: term(), NewState :: #state{}}).
%% handle_call({equery, Stmt, Params}, _From, #state{connection_pid = Conn}=State) ->
%%   ?LOG_DEBUG("Mi zdes' 2 ~n",[]),
%%   ?LOG_DEBUG("Conn ~p~n", [Conn]),
%%   {reply, pgsql:equery(Conn, Stmt, Params), State};
%% handle_call(_Request, _From, State) ->
%%   ?LOG_DEBUG("Mi zdes' 3 ~n",[]),
%%   {reply, ok, State}.
%%
%% %%--------------------------------------------------------------------
%% %% @private
%% %% @doc
%% %% Handling cast messages
%% %%
%% %% @end
%% %%--------------------------------------------------------------------
%% -spec(handle_cast(Request :: term(), State :: #state{}) ->
%%   {noreply, NewState :: #state{}} |
%%   {noreply, NewState :: #state{}, timeout() | hibernate} |
%%   {stop, Reason :: term(), NewState :: #state{}}).
%% handle_cast(_Request, State) ->
%%   {noreply, State}.
%%
%% %%--------------------------------------------------------------------
%% %% @private
%% %% @doc
%% %% Handling all non call/cast messages
%% %%
%% %% @spec handle_info(Info, State) -> {noreply, State} |
%% %%                                   {noreply, State, Timeout} |
%% %%                                   {stop, Reason, State}
%% %% @end
%% %%--------------------------------------------------------------------
%% -spec(handle_info(Info :: timeout() | term(), State :: #state{}) ->
%%   {noreply, NewState :: #state{}} |
%%   {noreply, NewState :: #state{}, timeout() | hibernate} |
%%   {stop, Reason :: term(), NewState :: #state{}}).
%% handle_info(connect, State) ->
%%   NewState = connect(State),
%%   {noreply, NewState};
%% handle_info({'EXIT', Ref, normal}, State)->
%%   erlang:demonitor(Ref),
%%   {stop, normal, State};
%% handle_info({'DOWN', Ref, _, _, _}, State)->
%%   erlang:demonitor(Ref),
%%   {stop, normal, State};
%% handle_info({'EXIT', _MonitorRef,Reason}, State)->
%% %%           erlang:demonitor(MonitorRef),
%%   {stop, Reason, State};
%% handle_info(check_healthy, State)->
%%   case eredis:q(State#state.connection_pid, ["GET", "ololo"]) of
%%     {ok, ReturnValue} when ReturnValue =:= undefined orelse is_binary(ReturnValue)-> {noreply, State};
%%     ErrorResp  ->
%%       ?LOG_ERROR("Connection are not healthy with reason ~p. turn off it", [ErrorResp]),
%%       {stop, ErrorResp, State}
%%   end;
%% handle_info(reconnection_limit, State)->
%%   {stop, normal, State};
%% handle_info(_Info, State) ->
%%   ?LOG_INFO("undefined info in ~p with message ~p", [self(), _Info]),
%%   {noreply, State}.
%%
%% %%--------------------------------------------------------------------
%% %% @private
%% %% @doc
%% %% This function is called by a gen_server when it is about to
%% %% terminate. It should be the opposite of Module:init/1 and do any
%% %% necessary cleaning up. When it returns, the gen_server terminates
%% %% with Reason. The return value is ignored.
%% %%
%% %% @spec terminate(Reason, State) -> void()
%% %% @end
%% %%--------------------------------------------------------------------
%% -spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
%%     State :: #state{}) -> term()).
%% terminate(normal, State) ->
%%   catch pgsql:close(State#state.connection_pid),
%%   ok;
%% terminate(Reason, _State) ->
%%   ?LOG_INFO("redis worker ~p terminated wtih reason ~p", [self(), Reason]),
%%   catch eredis:stop(_State#state.connection_pid),
%%   ok.
%%
%%
%% %%--------------------------------------------------------------------
%% %% @private
%% %% @doc
%% %% Convert process state when code is changed
%% %%
%% %% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% %% @end
%% %%--------------------------------------------------------------------
%% -spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
%%     Extra :: term()) ->
%%   {ok, NewState :: #state{}} | {error, Reason :: term()}).
%% code_change(_OldVsn, State, _Extra) ->
%%   {ok, State}.
%%
%% %%%===================================================================
%% %%% Internal functions
%% %%%===================================================================
%% connect(State) when State#state.reconnect_counter < ?RECONNECTION_LIMIT ->
%%   Host = proplists:get_value(host, State#state.config),
%%   Port = proplists:get_value(port, State#state.config),
%%   Password = proplists:get_value(password, State#state.config),
%%   Database = proplists:get_value(database, State#state.config, 0),
%%
%%   case eredis:start_link(Host,Port, Database, Password) of
%%     {ok, Conn} ->
%%       ?LOG_DEBUG("redis_worker: connected with pid ~p", [Conn]),
%%       erlang:monitor(process, Conn),
%%       {ok, Tref} = timer:send_interval(?DEF_HEALTH_CHECK_TIMEOUT, check_healthy),
%%       State#state{connection_pid = Conn, reconnect_counter = 0, health_check_tref = Tref};
%%     Error ->
%%       ?LOG_ERROR("redis_worker ~p: cannot  connect with message ~p reconnect try ~p", [self(), Error, State#state.reconnect_counter]),
%%       timer:sleep(State#state.reconnect_timeout),
%%       State#state{reconnect_counter = State#state.reconnect_counter + 1 }
%%   end;
%%
%% connect(_State)->
%%   ?LOG_ERROR("redis_worker: Reconnection limit in ~p", [self()]),
%%   self() ! reconnection_limit, _State.



-behaviour(gen_server).

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-define(DEFAULT_RECONNECT_TIMEOUT, 4000).

-define(DEF_HEALTH_CHECK_TIMEOUT, 60 * 1000).
-define(RECONNECTION_LIMIT, 5).
-define(SERVER, ?MODULE).
-include("template.hrl").

-record(state, {config, connection_pid, reconnect_timeout = ?DEFAULT_RECONNECT_TIMEOUT, reconnect_counter = 0, health_check_tref}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link(term()) ->
  {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link(Config) ->
  gen_server:start(?MODULE, [Config], []).

%% start_link() ->
%%   gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
  {ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term()} | ignore).
init([Config]) ->
  process_flag(trap_exit, true),
  self() ! connect,
  {ok, #state{config = Config}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
    State :: #state{}) ->
  {reply, Reply :: term(), NewState :: #state{}} |
  {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_call({equery, Query}, _From, State) when is_list(Query) ->
  ?LOG_DEBUG("Mi tyt 1 ~n",[]),
  ?LOG_DEBUG("ssss ~p~n",[eredis:q(State#state.connection_pid, Query)]),
  {reply, eredis:q(State#state.connection_pid, Query), State};
handle_call(_Request, _From, State) ->
  ?LOG_DEBUG("Mi tyt 2 ~n",[]),
  {reply, ok, State}.

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
    ?LOG_DEBUG("Mi tyt 3 ~n",[]),
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
  ?LOG_DEBUG("Mi tyt 4 ~n",[]),
  NewState = connect(State),
  {noreply, NewState};
handle_info({'EXIT', Ref, normal}, State)->
  ?LOG_DEBUG("Mi tyt 5 ~n",[]),
  erlang:demonitor(Ref),
  {stop, normal, State};
handle_info({'DOWN', Ref, _, _, _}, State)->
  ?LOG_DEBUG("Mi tyt 6 ~n",[]),
  erlang:demonitor(Ref),
  {stop, normal, State};
handle_info({'EXIT', _MonitorRef,Reason}, State)->
  ?LOG_DEBUG("Mi tyt 7 ~n",[]),
%%           erlang:demonitor(MonitorRef),
  {stop, Reason, State};
handle_info(check_healthy, State)->
  %?LOG_DEBUG("Mi tyt 8 ~n",[]),
  case eredis:q(State#state.connection_pid, ["GET", "ololo"]) of
    {ok, ReturnValue} when ReturnValue =:= undefined orelse is_binary(ReturnValue)-> {noreply, State};
    ErrorResp  ->
      ?LOG_ERROR("Connection are not healthy with reason ~p. turn off it", [ErrorResp]),
      {stop, ErrorResp, State}
  end;
handle_info(reconnection_limit, State)->
  ?LOG_DEBUG("Mi tyt 9 ~n",[]),
  {stop, normal, State};
handle_info(_Info, State) ->
  ?LOG_INFO("undefined info in ~p with message ~p", [self(), _Info]),
  {noreply, State}.

connect(State) when State#state.reconnect_counter < ?RECONNECTION_LIMIT ->
  Host = proplists:get_value(hostname, State#state.config),
  %?LOG_DEBUG("Host ~p~n" , [_Host]),
  ?LOG_DEBUG ("Config ~p~n", [State#state.config]),
  Port = proplists:get_value(port, State#state.config),
  Password = proplists:get_value(password, State#state.config),
  Database = proplists:get_value(database, State#state.config, 0),
  ?LOG_DEBUG("Mi tyt 10 ~n",[]),
  case eredis:start_link(Host, Port, Database, Password) of
    {ok, Conn} ->
      ?LOG_DEBUG("redis_worker: connected with pid ~p", [Conn]),
      erlang:monitor(process, Conn),
      {ok, Tref} = timer:send_interval(?DEF_HEALTH_CHECK_TIMEOUT, check_healthy),
      State#state{connection_pid = Conn, reconnect_counter = 0, health_check_tref = Tref};
    Error ->
      ?LOG_ERROR("redis_worker ~p: cannot  connect with message ~p reconnect try ~p", [self(), Error, State#state.reconnect_counter]),
      timer:sleep(State#state.reconnect_timeout),
      State#state{reconnect_counter = State#state.reconnect_counter + 1 }
  end;

connect(_State)->
  ?LOG_ERROR("redis_worker: Reconnection limit in ~p", [self()]),
  self() ! reconnection_limit, _State.

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
terminate(Reason, _State) ->
  ?LOG_INFO("redis worker ~p terminated wtih reason ~p", [self(), Reason]),
  catch eredis:stop(_State#state.connection_pid),
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
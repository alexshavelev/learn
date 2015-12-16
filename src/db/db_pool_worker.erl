%%%-------------------------------------------------------------------
%%% @author Vitali Kletsko
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. июн 2014 09:35
%%%-------------------------------------------------------------------
-module(db_pool_worker).
-author("Vitali Kletsko <v.kletsko@gmail.com>").

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


-include("template.hrl").

-record(state, {config, connection_pid}).

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
  gen_server:start_link(?MODULE, [Config], []).

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
handle_call({squery, Sql}, _From, #state{connection_pid = Conn}=State) ->
  ?LOG_DEBUG("Mi zdes' 1 ~n",[]),
  {reply, pgsql:squery(Conn, Sql), State};
handle_call({equery, Stmt, Params}, _From, #state{connection_pid = Conn}=State) ->
  ?LOG_DEBUG("Mi zdes' 2 ~n",[]),
  ?LOG_DEBUG("Conn ~p~n", [Conn]),
  {reply, pgsql:equery(Conn, Stmt, Params), State};
handle_call(_Request, _From, State) ->
  ?LOG_DEBUG("Mi zdes' 3 ~n",[]),
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
  Hostname = proplists:get_value(hostname, State#state.config),
  Database = proplists:get_value(database, State#state.config),
  Username = proplists:get_value(username, State#state.config),
  Password = proplists:get_value(password, State#state.config),
  case pgsql:connect(Hostname, Username, Password, [{database, Database}]) of
    {ok, Conn} ->
      io:format("~p Worker: connected with Pid: ~p", [psql, Conn]),
      erlang:monitor(process, Conn),
      State#state{connection_pid = Conn};
    Error ->
      io:format("~p Worker ~p: cannot connect with message: ~p~n", [psql, self(), Error]),
      State
  end.
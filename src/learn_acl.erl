-module(learn_acl).

-behaviour(gen_server).


-export([start_link/0,
        add/3,
        send_msg/2,
        delete_account/1,
        authorize/2,
        change_role/3,
        get_msg/2]).


-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {db=[]}).

-define(SERVER, ?MODULE).


start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
 

add(Login, Pass, Role) ->
  gen_server:call(?SERVER, {add, Login, Pass, Role}).


send_msg(Login, Message) ->
  ?SERVER ! {send_msg, Login, Message}. 

change_role(Login, Pass, NewRole) ->
  gen_server:call(?SERVER, {change_role, Login, Pass, NewRole}).

get_msg(Login, Pass) ->
  gen_server:call(?SERVER, {get_msg, Login, Pass}).



delete_account(Login) ->
  gen_server:cast(?SERVER, {destroy, Login}).


authorize(Login, Pass) ->
  gen_server:call(?SERVER, {authorize, Login, Pass}).


init(_Args) ->
  {ok, #state{}}.


  

handle_call({add, Login, Pass, Role},_From, State) ->
  io:format("add ~n"),
  Db = State#state.db,
  case lists:keyfind(Login, 1, Db) of
    false->
      io:format("add - reg new ~n"),
      {reply, registered, State#state{db=[{Login, erlang:md5(Pass), Role, ""}|Db]}};
     {_Key, _Result}-> 
      {reply, invalid_params, State}  
  end;




handle_call({authorize, Login, Pass}, _From, State) ->
   Db = State#state.db,
   case lists:keyfind(Login, 1, Db) of
      false ->
        {reply, no_user, State};
      {_Log, Pa, _Role, _Msg} ->
        VerPass = erlang:md5(Pass),
        if VerPass =:= Pa ->
          {reply, access, State};
        true ->
          {reply, invalid_login_or_password, State}
        end
    end;



handle_call({change_role, Login, _Pass, NewRole}, _From, State) ->
  Db = State#state.db,
  case lists:keyfind(Login, 1, Db) of
      false ->
        {reply, invalid_login_or_password, State};
      {Log, Pa, _Role, Msg} ->
        NewDb = lists:keydelete(Login, 1, Db),        
        {reply, role_changed, State#state{db=[{Log, Pa, NewRole, Msg}|NewDb]}}
  end;



handle_call({get_msg, Login, Pass}, _From, State) ->
  Db = State#state.db,
  case lists:keyfind(Login, 1, Db) of
      false ->
        {reply, no_account, State};
      {_Log, Pa, _Role, Msg} ->
        VerPass = erlang:md5(Pass),
        if VerPass =:= Pa ->
          {reply, Msg, State};
        true ->
          {reply, invalid_login_or_password2222, State}
        end
  end;


handle_call(_Request, _From, State) ->
  io:format("undef ~n"),
  Reply = not_matched_correctly,
  {reply, Reply, State}.

handle_cast({destroy, Login}, State) ->
  Db = State#state.db,
  io:format("ok delete ~n"),
  NewDb = lists:keydelete(Login, 1, Db),
  {noreply, State#state{db=NewDb}};


handle_cast(_Msg, State) ->
  io:format("undef delete ~n"),
  {noreply, State}.


handle_info({send_msg, Login, Message}, State) ->
  io:format("send msg YES ~n"),
  Db = State#state.db,
  case lists:keyfind(Login, 1, Db) of
      false ->
        {noreply, State};
      {Log, Pa, Role, _Msg} ->
        NewDb = lists:keydelete(Login, 1, Db),
        {noreply, State#state{db=[{Log, Pa, Role, Message}|NewDb]}}
  end;


handle_info(_Info, State) ->
  io:format("send mes undef ~n"),
  {noreply, State}.


terminate(_Reason, _State) ->
  ok.


code_change(_OldVsn, State, _Extra) ->
  {ok, State}.




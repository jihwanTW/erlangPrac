%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 11월 2017 오후 7:55
%%%-------------------------------------------------------------------
-module(erlangPrac_session_server).
-author("Twinny-KJH").


-behaviour(gen_server).

%% API
-export([start/0,lookup/1,insert/1,delete/1,session_timer/1]).


-export([start_link/0]).

%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-record(state, {}).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
  {ok, #state{}}.

handle_call({lookup,Session}, _From, State) ->
  Result = ets:lookup(session,Session),
  Reply = case Result of
    []->
      {error,jsx:encode([{<<"result">>,<<"invalid session">>}])};
    _->
      [{Session,User_idx,Pid}] = Result,
      Pid1 = list_to_pid(Pid),
      Pid1 ! {time},
      io:format("value = ~p ~n",[User_idx]),
      {ok,User_idx}
  end,
  {reply,Reply,State};
handle_call({insert,{User_id,User_idx}},_From,State)->
  random:seed(now()),
  Num = random:uniform(10000),

  Hash=erlang:phash2(User_id),

  List = io_lib:format("~.16B~.16B",[Hash,Num]),
  Session = list_to_binary(lists:append(List)),
  ets:insert(session,{Session,User_idx}),

  Pid = spawn(erlangPrac_session,session_timer,[now()]),
  ets:insert(session,{Session,User_idx,pid_to_list(Pid)}),
  erlang:send_after(1000,Pid,{check}),

  Reply = {ok,Session},
  {reply,Reply,State};
handle_call({delete,Session},_From,State)->
  Obj = ets:match_object(session,{Session,'_','_'}),
  Reply = case Obj of
    [] ->
      io:format("do not exist"),
      {error,<<"failed logout">>};
    _->
      [Obj1] = Obj,
      io:format("ets delete ~p ~n",[Session]),
      {_,_,Pid_list} = Obj1,
      Pid = list_to_pid(Pid_list),
      exit(Pid,normal),
      ets:delete_object(session,Obj1),
      {ok,<<"logout">>}
  end,
  {reply,Reply,State}
.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.




start()->
  gen_server:start_link({local,?MODULE},?MODULE,[],[]).

stop() -> gen_server:call(?MODULE,stop).


lookup(Session)-> gen_server:call(?MODULE,{lookup,Session}).

insert({User_idx,User_id}) -> gen_server:call(?MODULE,{insert,{User_idx,User_id}}).

delete(Session)->gen_server:call(?MODULE,{delete,Session}).



session_timer(Time)->
  Time1 =
    receive
      {time}->
        now();
%%    {Pid,Ref,_,_}->
%%      now();
      {check}->
        Diff = timer:now_diff(now(),Time),
        case (Diff > 10000*1000) of
          true-> delete_session();
          _-> erlang:send_after(1000,self(),{check})
        end,
        Time;
      _->
        Time
    end,
  session_timer(Time1).


delete_session()->
  [Obj] = ets:match_object(session,{'_','_',pid_to_list(self())}),
  case Obj of
    [] ->
      io:format("Obj : ~p ~n",Obj),
      io:format("do not exist");
    _->
      io:format("ets delete ~n"),
      ets:delete_object(session,Obj)
  end,
  exit(normal).
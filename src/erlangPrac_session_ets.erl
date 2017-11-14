%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 11월 2017 오후 4:10
%%%-------------------------------------------------------------------
-module(erlangPrac_session_ets).
-author("Twinny-KJH").

%% API
-export([lookup/2,insert/2,delete/2,init_store/1,session_timer/2]).

init_store(Pool_id)->
  ets:new(Pool_id,[public,named_table])
  .

lookup(Pool_id,Session)->
  io:format("lookup in ets PoolId [~p] Session[~p] ~n",[Pool_id,Session]),
  Result = ets:lookup(Pool_id,Session),
  case Result of
    []->
      {error,jsx:encode([{<<"result">>,<<"invalid session">>}])};
    _->
      [{Session,User_idx,Pid}] = Result,
      Pid1 = list_to_pid(Pid),
      Pid1 ! {time},
      {ok,User_idx}
  end
.


insert(Pool_id,{Session,User_idx})->
  Pid = spawn(?MODULE,session_timer,[Pool_id,Session]),
  erlang:send_after(1000,Pid,{check}),
  ets:insert(Pool_id,{Session,User_idx,pid_to_list(Pid)}),
  Pool_id
.


delete(Pool_id,Session)->
  Obj = ets:match_object(Pool_id,{Session,'_','_'}),
  case Obj of
    [] ->
      {ok,jsx:encode([{<<"result">>,<<"not exist">>}])};
    _->
      [Obj1] = Obj,
      {_,_, TempPid} = Obj1,
      Pid = list_to_pid(TempPid),
      Pid ! {stop},
      ets:delete_object(Pool_id,Obj1),
      {ok,jsx:encode([{<<"result">>,<<"logout">>}])}
  end
.



session_timer(Pool_id,Session)->
    receive
      {time}->
        now();
      {stop}->
        io:format("Session Stop : ~p ~n",[Session]),
        exit(normal);
      _->
        pass
    after 1000*60*60 ->
      io:format("session destroy : ~p ~n",[Session]),
      delete(Pool_id,Session)
    end,
  session_timer(Pool_id,Session).

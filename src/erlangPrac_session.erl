%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 11월 2017 오후 6:12
%%%-------------------------------------------------------------------
-module(erlangPrac_session).
-author("Twinny-KJH").

%% API
-export([check_session/1,save_session/1,session_timer/1,new_session/2]).


check_session(Session)->
  Result = ets:lookup(session,Session),
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

%% 세션 생성
new_session(User_idx,User_id)->
  random:seed(now()),
  Num = random:uniform(10000),

  Hash=erlang:phash2(User_id),

  List = io_lib:format("~.16B~.16B",[Hash,Num]),
  Session = list_to_binary(lists:append(List)),
  ets:insert(session,{Session,User_idx}),
  Session.


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

save_session({Session,User_idx,Pid})->
  ets:insert(session,{Session,User_idx,Pid})
  .

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
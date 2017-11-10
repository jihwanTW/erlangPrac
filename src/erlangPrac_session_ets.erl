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
-export([lookup/2,insert/2,delete/2,init_store/1]).

init_store(Pool_id)->
  ets:new(Pool_id,[public,named_table])
  .

lookup(Pool_id,Session)->
  io:format("lookup in ets PoolId [~p] Session[~p] ~n",[Pool_id,Session]),
  ets:lookup(Pool_id,Session)
.


insert(Pool_id,{Session,User_idx,Pid})->
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
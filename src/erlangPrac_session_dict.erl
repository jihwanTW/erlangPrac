%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 11월 2017 오후 3:33
%%%-------------------------------------------------------------------
-module(erlangPrac_session_dict).
-author("Twinny-KJH").

-behaviour(gen_server).

%% API
-export([lookup/2,insert/2,delete/2,init_store/1]).


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
  {ok, dict:new()}.



init_store(Pool_id)-> gen_server:call(?MODULE,{init,Pool_id}).

lookup(Dict_id,Session)-> gen_server:call(?MODULE,{lookup,Dict_id,Session}).
insert(Pool_id,{Session,User_idx,Pid})-> gen_server:call(?MODULE,{insert, Pool_id,{Session,User_idx,Pid}}).
delete(Pool_id,Session)-> gen_server:call(?MODULE,{delete, Pool_id,Session}).



handle_call({lookup, Pool_id,Session}, _From, Dict_list) ->
  Dict = dict_id_to_dict(Pool_id, Dict_list),
  Reply = try {User_idx,Pid} = dict:fetch(Session,Dict),
  [{Session,User_idx,Pid}]
  catch _:_->[]
  end,
  {reply, Reply, Dict_list};
%% dict 에 삽입
handle_call({insert, Pool_id,{Session,User_idx,Pid}}, _From, Dict_list) ->
  Dict = dict_id_to_dict(Pool_id, Dict_list),
  Dict1 = dict:store(Session,{User_idx,pid_to_list(Pid)},Dict),
  New_Dict_list = add_dict({Pool_id,Dict1}, Dict_list),
  Reply = Pool_id,
  {reply, Reply, New_Dict_list};
handle_call({delete, Pool_id,Session}, _From, Dict_list) ->
  Dict = dict_id_to_dict(Pool_id, Dict_list),
  Value = try {User_idx,Pid1} = dict:fetch(Session,Dict),
  [{Session,User_idx,Pid1}]
          catch _:_->[]
          end,
  {Reply,New_dict_list} = case Value of
    []->
      {{ok,jsx:encode([{<<"result">>,<<"not exist">>}])},Dict_list};
    _->
      % 조회값이 존재하면 실행
      % stop process
      [{_,_,TempPid}] = Value,
      Pid = list_to_pid(TempPid),
      Pid ! {stop},
      % remove value in dict
      NewDict = dict:erase(Session,Dict),
      {{ok,jsx:encode([{<<"result">>,<<"logout">>}])},add_dict({Pool_id,NewDict},Dict_list)}
  end,
  {reply, Reply, New_dict_list};
handle_call({init,Pool_id}, _From, Dict_list) ->
  New_Dict_list = add_dict({Pool_id,dict:new()}, Dict_list),
  {reply, Pool_id, New_Dict_list}.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.



dict_id_to_dict(Dict_id,State)->
  try dict:fetch(Dict_id,State)
  catch _:_->dict:new()
  end
  .

add_dict({Dict_id,Dict},State)->
  dict:store(Dict_id,Dict,State)
.

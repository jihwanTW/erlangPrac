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
-export([lookup/1,insert/1,delete/1,session_timer/3,change/1,state/0]).


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


lookup(Session)-> gen_server:call(?MODULE,{lookup,Session}).

insert({User_idx,User_id}) -> gen_server:call(?MODULE,{insert,{User_idx,User_id}}).

delete(Session)->gen_server:call(?MODULE,{delete,Session}).

change(NewState)->gen_server:call(?MODULE,{change,NewState}).

state()->gen_server:call(?MODULE,{state}).



init([]) ->
  {ok, {dict,dict:new()}}.

%% 조회
handle_call({lookup,Session}, _From, State) ->
  Reply = case State of
            {ets,_}->
              Result = ets:lookup(session,Session),
              case Result of
                []->
                  {error,jsx:encode([{<<"result">>,<<"invalid session">>}])};
                _->
                  [{Session,User_idx,Pid}] = Result,
                  Pid1 = list_to_pid(Pid),
                  Pid1 ! {time},
                  {ok,User_idx}
              end;
            {dict,Dict}->
              Result = try dict:fetch(Session,Dict)
                        catch _:_->[]
                        end,
              case Result of
                []->
                  {error,jsx:encode([{<<"result">>,<<"invalid session">>}])};
                _->
                  {User_idx,Pid} = Result,
                  Pid1 = list_to_pid(Pid),
                  Pid1 ! {time},
                  {ok,User_idx}
              end
          end,
  {reply,Reply,State};
%% 세션 인서트
handle_call({insert,{User_id,User_idx}},_From,State)->
  Now = now(),
  % generate session
  random:seed(Now),
  Num = random:uniform(10000),
  Hash=erlang:phash2(User_id),
  List = io_lib:format("~.16B~.16B",[Hash,Num]),
  Session = list_to_binary(lists:append(List)),

  % generate process
  Pid = spawn(erlangPrac_session_server,session_timer,[Now,State,Session]),
  % session insert to db
  NewState =
    case State of
      {dict,Dict}->
        {dict,dict:store(Session,{User_idx,pid_to_list(Pid)},Dict)};
      {ets,_}->
        ets:insert(session,{Session,User_idx,pid_to_list(Pid)}),
        State
    end,
  erlang:send_after(1000,Pid,{check}),

  Reply = {ok,Session},
  {reply,Reply,NewState};
%% 세션삭제
handle_call({delete,Session},_From,State)->
  {Reply,NewState} = remove_session(State,Session),
  {reply,Reply,NewState};
%% 저장장소 바꿈
handle_call({change,ChangeUnit},_From,State)->
  {Reply,NewState} = case ChangeUnit of
               ets->
                 % 기존저장소에 대한 프로세스 제거
                 {_,Dict} = State,
                 KeyList = dict:fetch_keys(Dict),
                 ClearProcess =
                   fun(Key)-> Value = dict:fetch(Key,Dict),
                     {_,TempPid} = Value,
                     Pid = list_to_pid(TempPid),
                     Pid ! {stop},
                     Pid
                     end,
                 lists:map(ClearProcess,KeyList),
                 {{ok,jsx:encode([{<<"result">>,<<"change to ets">>}])},{ets,dict:new()}};
               dict->
                 % 기존저장소에 대한 프로세스 제거
                 Obj = ets:match_object(session,{'_','_','_'}),
                 ClearProcess =
                   fun(Value)-> {_,_,TempPid} = Value,
                     Pid = list_to_pid(TempPid),
                     Pid ! {stop},
                     Pid
                   end,
                 lists:map(ClearProcess,Obj),
                 ets:delete_all_objects(session),
                 {_,Dict} = State,
                 {{ok,jsx:encode([{<<"result">>,<<"change to dict">>}])},{dict,Dict}};
               _->
                 {{ok,jsx:encode([{<<"result">>,<<"not change">>}])},State}
  end,
  {reply,Reply,NewState};
handle_call({state},_From,State)->
  {CurrentDB,_} = State,
  Reply = {ok,CurrentDB},
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


%% 현재 state값에 따라 삭제하는위치가 달라짐
remove_session(State,Session)->
  Result = case State of
    {dict,Dict}->
      Value =
        try dict:fetch(Session,Dict)
        catch _:_->[]
        end,
      case Value of
        []->
          % 조회값이 없으면 실행
          {{ok,<<"not exist">>},State};
        _->
          % 조회값이 존재하면 실행
          % stop process
          {_,TempPid} = Value,
          Pid = list_to_pid(TempPid),
          Pid ! {stop},
          % remove value in dict
          NewState = {dict,dict:erase(Session,Dict)},
          {{ok,<<"logout">>},NewState}
      end;
    {ets,_}->
      Obj = ets:match_object(session,{Session,'_','_'}),
      case Obj of
        [] ->
          {{error,<<"failed logout">>},State};
        _->
          [Obj1] = Obj,
          {_,_, TempPid} = Obj1,
          Pid = list_to_pid(TempPid),
          Pid ! {stop},
          ets:delete_object(session,Obj1),
          {{ok,<<"logout">>},State}
      end
  end,
  Result.


%% 현재 state값에 따라 lookup하는 위치가 달라짐
session_timer(Time,State,Session)->
  Time1 =
    receive
      {time}->
        now();
      {check}->
        Diff = timer:now_diff(now(),Time),
        case (Diff > 360000*1000*1000) of
          true->
            io:format("session destroy : ~p ~n",[Session]),
            remove_session(State,Session);
          _-> erlang:send_after(1000,self(),{check})
        end,
        Time;
      {stop}->
        io:format("Session Stop : ~p ~n",[Session]),
        exit(normal);
      _->
        Time
    end,
  session_timer(Time1,State,Session).

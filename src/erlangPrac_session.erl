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

-behaviour(gen_server).

%% API
-export([lookup/1,insert/1,delete/1,session_timer/2]).


-export([start_link/2]).

%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-record(state, {}).

start_link(Mod,Pool_id) ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [Mod,Pool_id], []).


lookup(Session)-> gen_server:call(?MODULE,{lookup,Session}).

insert({User_idx,User_id}) -> gen_server:call(?MODULE,{insert,{User_idx,User_id}}).

delete(Session)->gen_server:call(?MODULE,{delete,Session}).





init([Mod,Pool_id]) ->
  Mod_id = Mod:init_store(Pool_id),
  {ok, {Mod,Mod_id}}.


%% 조회
handle_call({lookup,Session}, _From, State) ->
  {Mod,Mod_id} = State,
  Result = Mod:lookup(Mod_id ,Session),
  Reply = case Result of
                []->
                  {error,jsx:encode([{<<"result">>,<<"invalid session">>}])};
                _->
                  [{Session,User_idx,Pid}] = Result,
                  Pid1 = list_to_pid(Pid),
                  Pid1 ! {time},
                  {ok,User_idx}
              end,
  {reply,Reply, State};
%% 세션 인서트
handle_call({insert,{User_id,User_idx}},_From, State)->
  {Mod,Mod_id} = State,
  Now = now(),
  % generate session
  random:seed(Now),
  Num = random:uniform(10000),
  Hash=erlang:phash2(User_id),
  List = io_lib:format("~.16B~.16B",[Hash,Num]),
  Session = list_to_binary(lists:append(List)),

  % generate process
  Pid = spawn(erlangPrac_session,session_timer,[Now,Session]),
  % session insert to db
  New_mod_id = Mod:insert(Mod_id,{Session,User_idx,Pid}),
  erlang:send_after(1000,Pid,{check}),

  Reply = {ok,Session},
  New_state = {Mod,New_mod_id},
  {reply,Reply, New_state};
%% 세션삭제
handle_call({delete,Session},_From,State)->
  {Mod,Mod_id} = State,
  Reply = Mod:delete(Mod_id,Session),
  {reply,Reply, State}
.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.



session_timer(Time,Session)->
  Time1 =
    receive
      {time}->
        now();
      {check}->
        Diff = timer:now_diff(now(),Time),
        case (Diff > 60*1000*1000) of
          true->
            io:format("session destroy : ~p ~n",[Session]),
            delete(Session);
          _-> erlang:send_after(1000,self(),{check})
        end,
        Time;
      {stop}->
        io:format("Session Stop : ~p ~n",[Session]),
        exit(normal);
      _->
        Time
    end,
  session_timer(Time1,Session).

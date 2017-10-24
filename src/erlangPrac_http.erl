%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 10월 2017 오후 1:53
%%%-------------------------------------------------------------------
-module(erlangPrac_http).
-author("Twinny-KJH").

%% API
-export([init/3,handle/2,terminate/3]).


init(_Type,Req,[]) ->
  {ok,Req,no_state}.

handle(Req,State)->
  {Api,Req1} = cowboy_req:binding(api,Req),
  {What,Req2} = cowboy_req:binding(what,Req1),
  {Opt,Req3} = cowboy_req:binding(opt,Req2),
  %% 데이터 로딩
  {ok,Data,Req4} = cowboy_req:body_qs(Req3),
  io:format("api=~p, what=~p,opt=~p id=~p pw=~p ~n",[Api,What,Opt,proplists:get_value(<<"id">>,Data),proplists:get_value(<<"pw">>,Data)]),

  %% 디비풀 생성.
  connect_db(),

  Reply = handle(Api,What,Opt,Data),

  {ok,Req5} = cowboy_req:reply(200,[
    {<<"content-type">>,<<"text/plain">>}
  ], Reply,Req4),
  {ok,Req5,State}.

handle(<<"login">>,_,_,Data)->
  Id = proplists:get_value(<<"id">>,Data),
  Password= proplists:get_value(<<"pw">>,Data),
  case dets:lookup(users_list,Id) of
    [{Id,Password}]->
      <<"{\"result\":\"ok\"}">>;
    _ ->
      <<"{\"result\":\"fail\"}">>
  end;
handle(<<"user">>,<<"register">>,_,Data) ->
  register_user(Data);
handle(<<"user">>,<<"update">>,_,Data) ->
  update_user(Data);
handle(<<"user">>,<<"send_dialog">>,_,Data) ->
  send_dialog(Data);
handle(<<"chatting">>,<<"view">>,_,Data) ->
  view_dialog(Data);
handle(_,_,_,_)->
  <<"{\"result\":\"error\"}">>.

%% 유저 가입시키기
register_user(Data)->
  %% Data에 id,pw,email,nickname이 모두 존재하는지 여부 조회해야함.

  %% 아이디 비밀번호 변수에 저장.
  Name=proplists:get_value(<<"name">>,Data),
  Email=proplists:get_value(<<"email">>,Data),
  Nickname=proplists:get_value(<<"nickname">>,Data),

  %% 중복체크
  emysql:prepare(check_user,<<"SELECT * FROM user WHERE name=? or email=? ">>),
  {_,_,_,Result,_} = emysql:execute(chatting_db,check_user,[Name,Email]),
  case Result of
    [] ->
      %% 디비에 데이터 추가.
      emysql:prepare(register_user,<<"INSERT INTO user (name,email,nickname,date_time) values(?, ?, ?, now())">>),
      emysql:execute(chatting_db,register_user,[Name,Email,Nickname]),
      jsx:encode([{<<"result">>,<<"Register">>}]);
    _ ->
      %%
      jsx:encode([{<<"result">>,<<"Duplicate">>}])
  end.

%% 유저 정보변경
update_user(Data)->
  Idx = proplists:get_value(<<"idx">>,Data),
  Email = proplists:get_value(<<"email">>,Data),
  Nickname = proplists:get_value(<<"nickname">>,Data),
  emysql:prepare(update_user,<<"UPDATE user SET email=?, nickname=? WHERE idx=?">>),
  Result = emysql:execute(chatting_db,update_user,[Email,Nickname,Idx]),
  %% 성공여부 반환
  case Result of
    [] ->
      jsx:encode([{<<"result">>,<<"does not exist">>}]);
    _ ->
      jsx:encode([{<<"result">>,<<"Change Data">>}])
  end.

%% 대화보내기
%% TODO : 방이 존재하는지 여부 . 방에 유저가 존재하는지 여부. ( 단체방일경우 )
send_dialog(Data)->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Room_idx = proplists:get_value(<<"room_idx">>,Data),
  Dialog = proplists:get_value(<<"dialog">>,Data),
  emysql:prepare(insert_dialog,<<"INSERT INTO dialog (room_idx,user_idx,user_dialog,date_time) values(?, ?, ?,now())">>),
  emysql:execute(chatting_db,insert_dialog,[User_idx,Room_idx,Dialog]),
  jsx:encode([{<<"result">>,<<"send dialog">>}]).


%% 대화 조회 .
%% TODO : 방이 존재하는지여부. 방에 내가 존재하는지 여부 // 현재 대화가 어디까지 갱신되었나 여부 확인후, 조회
view_dialog(Data)->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Room_idx = proplists:get_value(<<"room_idx">>,Data),
  Read_idx = proplists:get_value(<<"read_idx">>,Data),
  emysql:prepare(view_dialog,<<"SELECT * FROM dialog WHERE room_idx=? and idx > ?">>),
  Result = emysql:execute(chatting_db,view_dialog,[Room_idx,Read_idx]),
  ViewDialogJson = emysql_util:as_json(Result),
%%  print_views(ViewDialogJson),
  io:format(<<"view Dialog ~n">>),
  jsx:encode(ViewDialogJson)
  .

%%print_views([H|T])->
%%  Dialog = proplists:get_value(<<"user_dialog">>,H),
%%  io:format(jsx:encode(H)),
%%  io:format("~n"),
%%  print_views(T);
%%print_views([])->io:format(jsx:encode([{<<"result">>,<<"view dialog end">>}])).

%% 디비에 연결하여 db pool 생성하기.
connect_db()->
  emysql:add_pool(
    chatting_db,
    [{size,1},
      {user,"root"},
      {password,"jhkim1020"},
      {database,"erlangprac_chattingdb"},
      {encoding,utf8}
    ]).


terminate(_Reason,_Req,_State)->ok.
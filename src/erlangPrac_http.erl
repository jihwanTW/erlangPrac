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
  io:format("name = ~p , ~p , ~p ~n",[Name,Email,Nickname]),

  %% 중복체크
  emysql:prepare(register_user,<<"SELECT * FROM user WEHRE name=? or email=? ">>),
  Result = emysql:execute(chatting_db,register_user,[Name,Email]),
  case Result of
    [] ->
      %% 디비에 데이터 추가.
      emysql:prepare(register_user,<<"INSERT INTO user (name,email,nickname) values(?, ?, ?)">>),
      emysql:execute(chatting_db,register_user,[Name,Email,Nickname]),
    <<"{\"result\":\"Register\"}">>;
    _ ->
      %%
      <<"{\"result\":\"Duplicate\"}">>
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
      <<"{\"result\":\"does not exist\"}">>;
    _ ->
      <<"{\"result\":\"Change Data\"}">>
  end.

%% 대화보내기
send_dialog(Data)->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Room_idx = proplists:get_value(<<"room_idx">>,Data),
  Dialog = proplists:get_value(<<"dialog">>,Data),
  emysql:prepare(insert_dialog,<<"INSERT INTO dialog (room_idx,user_idx,user_dialog,date_time) values(?, ?, ?,now())">>),
  emysql:execute(chatting_db,insert_dialog,[User_idx,Room_idx,Dialog]),
  <<"send dialog">>.


%% 대화 조회
%% TODO : 방이 존재하는지여부. 방에 내가 존재하는지 여부
view_dialog(Data)->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Room_idx = proplists:get_value(<<"room_idx">>,Data),
  emysql:prepare(view_dialog,<<"SELECT * FROM dialog WHERE room_idx=?">>),
  Result = emysql:execute(chatting_db,view_dialog,[Room_idx]),
  ViewDialogJson = emysql_util:as_json(Result),
  print_views(ViewDialogJson),
  <<"chatting END">>
  .


print_views([H|T])->
  Dialog = proplists:get_value(<<"user_dialog">>,H),
  io:format("value = ~p ~n",[Dialog]),
  print_views(T);
print_views([])->io:format(<<"dialog end">>).

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

%% emysql 연습
run() ->
  emysql:add_pool(
    hello_pool,
    [{size,1},
      {user,"root"},
      {password,"jhkim1020"},
      {database,"hello_database"},
      {encoding,utf8}
    ]),
  emysql:prepare(my_stmt,<<"SELECT * from hello_table WHERE idx = ?">>),
  Result1 = emysql:execute(hello_pool, my_stmt, [1]),
  JSON1 = emysql_util:as_json(Result1),
  io:format("JOSN1 RESULT : ~n~p~n",[JSON1]),

  emysql:execute(hello_pool, <<"INSERT INTO hello_table SET hello_text = 'Hello World!'">>),

  Result=emysql:execute(hello_pool,
    <<"select hello_text from hello_table">>),

  JSON = emysql_util:as_json(Result),
  io:format("~n~p~n",[JSON]),
  A = 54,
  <<" ERROR : JSON ",A," Value","C">>.




terminate(_Reason,_Req,_State)->ok.
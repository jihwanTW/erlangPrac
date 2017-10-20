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
handle(<<"chatting">>,<<"register">>,_,Data) ->
  register_user(Data);
handle(<<"mysql">>,<<"connect">>,_,Data)->
  run();
handle(_,_,_,_)->
  <<"{\"result\":\"error\"}">>.

%% 유저 가입시키기
register_user(Data)->
  %% Data에 id,pw,email,nickname이 모두 존재하는지 여부 조회해야함.

  %% 아이디 비밀번호 변수에 저장.
  Name=proplists:get_value(<<"name">>,Data),
  Email=proplists:get_value(<<"email">>,Data),
  Nickname=proplists:get_value(<<"nickname">>,Data),

  %% 디비에 데이터 추가.
  %% TODO : 중복체크하기. (email,nickname)
%%   emysql:execute(chatting_db,<<"INSERT INTO user key (name,email,nickname) values('",Name,"','",Email,"','",Nickname,"')">>),
  emysql:prepare(register_user,<<"INSERT INTO user key (name,email,nickname) values('?','?','?')">>),
  emysql:execute(chatting_db,register_user,[Name,Email,Nickname]),
  <<"REGISTER USER -NAME : ",Name," -Email : ",Email," -Nickname : ",Nickname>>
  .


%% 디비에 연결하여 db pool 생성하기.
connect_db()->
  emysql:add_pool(
    chatting_db,
    [{size,1},
      {user,"root"},
      {password,"jhkim1020"},
      {database,"erlangprac_chatingdb"},
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
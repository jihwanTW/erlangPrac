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
handle(<<"join">>,_,_,Data) ->
Id=proplists:get_value(<<"id">>,Data),
Password=proplists:get_value(<<"pw">>,Data),
  dets:insert(users_list,{Id,Password}),
<<"{\"result\':\"join\"}">>;
handle(<<"hello">>,<<"world">>,_,_)->
  <<"{\"result\":\"Hello World\"}">>;
handle(<<"calculate">>,<<"sum">>,_,Data)->
  SumList = proplists:get_value(<<"sumList">>,Data),
  <<"{\"result\":\"error2222\"}">>;
%%  io:format("value = ~p ~n",[func(sum, SumList)]);
handle(<<"mysql">>,<<"connect">>,_,Data)->
  run();
handle(_,_,_,_)->
  <<"{\"result\":\"error\"}">>.


func(sum,[])->0 ;
func(sum,[H|T])->H+func(sum,T).


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

  emysql:execute(hello_pool, <<"INSERT INTO hello_table SET hello_text = 'Hello World!">>),

  Result=emysql:execute(hello_pool,
    <<"select hello_text from hello_table">>),

  JSON = emysql_util:as_json(Result),
  io:format("~n~p~n",[JSON]),
  A = 54,
  <<" ERROR : JSON ",A," Value","C">>.


terminate(_Reason,_Req,_State)->ok.
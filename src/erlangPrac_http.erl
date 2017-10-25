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
  erlangPrac_user:register_user(Data);
handle(<<"user">>,<<"update">>,_,Data) ->
  erlangPrac_user:update_user(Data);
handle(<<"user">>,<<"send_dialog">>,_,Data) ->
  erlangPrac_user:send_dialog(Data);
handle(<<"chatting">>,<<"view">>,_,Data) ->
  erlangPrac_user:view_dialog(Data);
handle(_,_,_,_)->
  <<"{\"result\":\"error\"}">>.




terminate(_Reason,_Req,_State)->ok.
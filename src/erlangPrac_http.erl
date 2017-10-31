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
  [{ExportJSON,_}] = Data,

  {HttpStateCode,Reply}= handle(Api,What,Opt,jsx:decode(ExportJSON)),

  {ok,Req5} = cowboy_req:reply(HttpStateCode,[
    {<<"content-type">>,<<"text/plain">>}
  ], Reply,Req4),
  {ok,Req5,State}.

%% 유저 가입관련 함수
handle(<<"user">>,<<"register">>,_,Data) ->
  Result = check_input(user_register,Data, erlangPrac_user:user_register(Data)),
  append_http_code(Result);
handle(<<"user">>,<<"update">>,_,Data) ->
  Result = check_input(user_update,Data, erlangPrac_user:user_update(Data)),
  append_http_code(Result);

%% 유저 대화관련 함수
handle(<<"user">>,<<"dialog">>,<<"send">>,Data) ->
  Result = check_input(dialog_send,Data, erlangPrac_user:dialog_send(Data)),
  append_http_code(Result);
handle(<<"user">>,<<"dialog">>,<<"view">>,Data) ->
  Result = check_input(dialog_view,Data,erlangPrac_user:dialog_view(Data)),
  append_http_code(Result);

%% 친구 관련 함수
handle(<<"user">>,<<"friend">>,<<"add">>,Data) ->
  Result = check_input(friend_add,Data, erlangPrac_user:friend_add(Data)),
  append_http_code(Result);
handle(<<"user">>,<<"friend">>,<<"remove">>,Data) ->
  Result = check_input(friend_remove,Data, erlangPrac_user:friend_remove(Data)),
  append_http_code(Result);
handle(<<"user">>,<<"friend">>,<<"view">>,Data) ->
  Result =  check_input(friend_view,Data,erlangPrac_user:friend_view(Data)),
  append_http_code(Result);
handle(<<"user">>,<<"friend">>,<<"suggest_view">>,Data) ->
  Result = check_input(friend_suggest_view,Data, erlangPrac_user:friend_suggest_view(Data)),
  append_http_code(Result);
handle(<<"user">>,<<"friend">>,<<"name_update">>,Data) ->
  Result = check_input(friend_name_update,Data, erlangPrac_user:friend_name_update(Data)),
  append_http_code(Result);

handle(<<"user">>,<<"friend">>,<<"add_favorites">>,Data) ->
  Result = check_input(friend_add_favorites,Data, erlangPrac_user:friend_add_favorites(Data)),
  append_http_code(Result);
handle(<<"user">>,<<"friend">>,<<"remove_favorites">>,Data) ->
  Result = check_input(friend_remove_favorites,Data, erlangPrac_user:friend_remove_favorites(Data)),
  append_http_code(Result);
handle(<<"user">>,<<"friend">>,<<"favorites_name_update">>,Data) ->
  Result = check_input(friend_favorites_name_update,Data, erlangPrac_user:friend_favorites_name_update(Data)),
  append_http_code(Result);
handle(<<"user">>,<<"friend">>,<<"favorites_move">>,Data) ->
  Result = check_input(friend_favorites_move,Data, erlangPrac_user:friend_favorites_move(Data)),
  append_http_code(Result);
handle(_,_,_,_)->
  {404,jsx:encode([{<<"result">>,<<"undefined url">>}])}.


check_input(RequestAtom,Data,Function)->
  InputResult = erlangPrac_check_input:check_input(RequestAtom,Data),
  if InputResult == true ->
    Function;
    true->
      InputResult
  end
  .

append_http_code(Result)->
  % tuple 값이 들어오면, 해당부분은 상태코드가 포함된 에러값이 리턴된것이므로, 그대로 반환.
  {State,JSON} = Result,
  case State of
    error->{400,JSON};
    ok->{200,JSON};
    _->{500,jsx:encode([{"result","state is not return"}])}
  end
  .



terminate(_Reason,_Req,_State)->ok.
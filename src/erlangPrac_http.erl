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
  % 데이터 로딩
  {ok, [{JsonData,_}],Req4} = cowboy_req:body_qs(Req3),
  % JSON 형태로 들어온 데이터 decode
  DecodeData = jsx:decode(JsonData),
  % 인풋데이터 존재여부와 세션키를 필요로하면 세션값체크
  CheckResult = erlangPrac_check_input:check_input({Api,What,Opt},DecodeData),
  % api 호출
  FunctionResult = case CheckResult of
                    {ok,undefined}->
                      try handle(Api,What,Opt,DecodeData)
                      catch T:Why ->
                        io:format("Why(no session) : [~p] ~p~n~p ~n",[T,Why,erlang:get_stacktrace()]),
                        {error,jsx:encode([{<<"result">>,<<"check error log">>}])}
                      end;
                    {ok,User_idx}->
                      try handle(Api,What,Opt,{User_idx,DecodeData})
                      catch T:Why ->
                        io:format("Why(no session) : [~p] ~p~n~p ~n",[T,Why,erlang:get_stacktrace()]),
                        {error,jsx:encode([{<<"result">>,<<"check error log">>}])}
                      end;
                    {error,_}->CheckResult
  end,
  % http 상태코드 붙임
  {HttpStateCode,Reply} = append_http_code(FunctionResult),

  {ok,Req5} = cowboy_req:reply(HttpStateCode,[
    {<<"content-type">>,<<"application/json">>}
  ], Reply,Req4),
  {ok,Req5,State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 유저 관련 함수
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 유저 가입
handle(<<"user">>,<<"register">>,_,Data) ->
  erlangPrac_user:user_register(Data);
%% 회원 탈퇴
handle(<<"user">>,<<"withdrawal">>,_,Data) ->
  erlangPrac_user:user_withdrawal(Data);
%% 유저 로그인
handle(<<"user">>,<<"login">>,_,Data) ->
  erlangPrac_user:user_login(Data);
%% 유저 정보 업데이트
handle(<<"user">>,<<"update">>,_,Data) ->
  erlangPrac_user:user_update(Data);
%% 유저 로그아웃
handle(<<"user">>,<<"logout">>,_,Data) ->
  erlangPrac_user:user_logout(Data);
%% 유저 정보보기
handle(<<"user">>,<<"info">>,_,Data) ->
  erlangPrac_user:user_info(Data);
handle(<<"user">>,<<"room">>,<<"leave">>,Data) ->
  erlangPrac_user:user_room_leave(Data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 유저 대화관련 함수
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 대화 보내기
handle(<<"user">>,<<"dialog">>,<<"send">>,Data) ->
  erlangPrac_user:dialog_send(Data);
%% 대화 조회
handle(<<"user">>,<<"dialog">>,<<"view">>,Data) ->
  erlangPrac_user:dialog_view(Data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 친구 관련 함수
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 친구 추가
handle(<<"user">>,<<"friend">>,<<"add">>,Data) ->
  erlangPrac_user:friend_add(Data);
%% 친구 삭제
handle(<<"user">>,<<"friend">>,<<"remove">>,Data) ->
  erlangPrac_user:friend_remove(Data);
%% 친구목록보기
handle(<<"user">>,<<"friend">>,<<"view">>,Data) ->
  erlangPrac_user:friend_view(Data);
%% 추천친구 보기
handle(<<"user">>,<<"friend">>,<<"suggest_view">>,Data) ->
  rlangPrac_user:friend_suggest_view(Data);
%% 친구이름수정
handle(<<"user">>,<<"friend">>,<<"name_update">>,Data) ->
  erlangPrac_user:friend_name_update(Data);

%% 즐겨찾기에 추가
handle(<<"user">>,<<"friend">>,<<"add_favorites">>,Data) ->
  erlangPrac_user:friend_add_favorites(Data);
%% 즐겨찾기에서 제거
handle(<<"user">>,<<"friend">>,<<"remove_favorites">>,Data) ->
  erlangPrac_user:friend_remove_favorites(Data);
%% 즐겨찾기이름 변경
handle(<<"user">>,<<"friend">>,<<"favorites_name_update">>,Data) ->
  erlangPrac_user:friend_favorites_name_update(Data);
%% 유저 다른 즐겨찾기로 옮기기
handle(<<"user">>,<<"friend">>,<<"favorites_move">>,Data) ->
  erlangPrac_user:favorite_move(Data);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 일정 관련 함수
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 일정 및 알람 추가
%% need param
%%  > session
%%  > start_timestamp
%%  > end_timestamp
%%  > subject
%%  > contents
%%  > alarm_info (timestamp) ,로 구분하여 사용
%% +반복여부
handle(<<"user">>,<<"schedule">>,<<"add">>,Data) ->
  pass;
%% 일정 수정 / 알람 추가,수정,삭제
handle(<<"user">>,<<"schedule">>,<<"fixed">>,Data) ->
  pass;
%% 일정 삭제
handle(<<"user">>,<<"schedule">>,<<"remove">>,Data) ->
  pass;
%% 일정 공유
handle(<<"user">>,<<"schedule">>,<<"share">>,Data) ->
  pass;
%% 일정 공유 제거 ( 공유한사람이 해당공유자 제거 )
handle(<<"user">>,<<"schedule">>,<<"share_remove">>,Data) ->
  pass;
%% 일정 공유 끊기 ( 공유된사람이 해당공유 제거 )
handle(<<"user">>,<<"schedule">>,<<"share_hang_up">>,Data) ->
  pass;
%% 일정 공유 리스트 ( 공유된 유저들 목록 - 마스터 포함 . 마스터는 제거 가능 )
handle(<<"user">>,<<"schedule">>,<<"share_list">>,Data) ->
  pass;
handle(<<"user">>,<<"schedule">>,<<"">>,Data) ->
  pass;
handle(<<"user">>,<<"schedule">>,<<"">>,Data) ->
  pass;

handle(_,_,_,_)->
  {404,jsx:encode([{<<"result">>,<<"undefined url">>}])}.


%% http state 코드를 붙이는 함수
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
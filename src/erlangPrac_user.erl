%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 10월 2017 오후 4:32
%%%-------------------------------------------------------------------
-module(erlangPrac_user).
-author("Twinny-KJH").

%% API
-export([register_user/1,update_user/1,send_dialog/1,view_dialog/1]).

%% 유저 가입시키기
register_user(Data)->
  %% 아이디 비밀번호 변수에 저장.

  %% 닉네임과 이메일 중복체크
  {_,_,_,Result,_} =  erlangPrac_query:query(check_duplicate,Data),
  case Result of
    [] ->
      %% 디비에 데이터 추가.
      erlangPrac_query:query(register_user,Data),
      jsx:encode([{<<"result">>,<<"Register">>}]);
    _ ->
      %% 중복되므로, Duplicate 메세지 전달
      jsx:encode([{<<"result">>,<<"Duplicate">>}])
  end.

%% 유저 정보변경
update_user(Data)->
  %% 중복닉네임 , 이메일 체크,
  %% 성공여부 반환
  {_,_,_,Result,_} = erlangPrac_query:query(check_duplicate,Data),
  case Result of
    [] ->
      %% 이메일이나 닉네임이 중복되지 않으면, DB에서 닉네임과 이메일 변경
      erlangPrac_query:query(update_user,Data),
      jsx:encode([{<<"result">>,<<"Change Data">>}]);
    _ ->
      %% 이메일이나 닉네임이 이미 존재하면, Exist Data 메세지 전송
      jsx:encode([{<<"result">>,<<"Exist Data">>}])
  end.

%% 대화보내기
send_dialog(Data)->
  %% 방에 유저가 존재하는지여부 조회
  {_,_,_,Result,_} = erlangPrac_query:query(check_room,Data),
  case Result of
    []->
      %% 유저가 방에 존재하지 않을경우 , 아래 문자열 전달
      jsx:encode([{<<"result">>,<<"not exist user in room">>}]);
    _->
      %% 유저가 방에 존재할 경우, 다이얼로그에 추가
      erlangPrac_query:query(insert_dialog,Data),
      jsx:encode([{<<"result">>,<<"send dialog">>}])
  end.


%% 대화 조회 .
view_dialog(Data)->
  %% 방에 유저가 존재하는지여부 조회
  {_,_,_,Result,_} = erlangPrac_query:query(check_room,Data),
  case Result of
    []->
      %% 유저가 방에 존재하지 않을경우 , 아래 문자열 전달
      jsx:encode([{<<"result">>,<<"not exist user in room">>}]);
    _->
      %% 현재까지 읽은 dialog idx 를 확인한 후에 그 이후의 데이터에 대해 읽어옴
      DialogResult = erlangPrac_query:query(view_dialog,Data),
      io:format(<<"view Dialog ~n">>),
      jsx:encode(emysql_util:as_json(DialogResult))
  end.
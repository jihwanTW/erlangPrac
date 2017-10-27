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
-export([user/2,dialog/2,friend/2]).

%% 유저 가입시키기
user(RequestAtom,Data) when RequestAtom =:= user_register->
  %% 닉네임과 이메일 중복체크
      Name=proplists:get_value(<<"name">>,Data),
      Email=proplists:get_value(<<"email">>,Data),
      Nickname=proplists:get_value(<<"nickname">>,Data),
  {_,_,_,Result,_} =  erlangPrac_query:query(check_duplicate,Nickname,Email),
  case Result of
    [] ->
      %% 디비에 데이터 추가.
      erlangPrac_query:query(register_user,Name,Email,Nickname),
      jsx:encode([{<<"result">>,<<"Register">>}]);
    _ ->
      %% 중복되므로, Duplicate 메세지 전달
      jsx:encode([{<<"result">>,<<"Duplicate">>}])
  end;
%% 유저 정보변경
user(RequestAtom,Data) when RequestAtom =:= user_update->
  Idx = proplists:get_value(<<"idx">>,Data),
  Email = proplists:get_value(<<"email">>,Data),
  Nickname = proplists:get_value(<<"nickname">>,Data),
  %% 중복닉네임 , 이메일 체크,
  %% 성공여부 반환
  {_,_,_,Result,_} = erlangPrac_query:query(check_duplicate,Nickname,Email),
  case Result of
    [] ->
      %% 이메일이나 닉네임이 중복되지 않으면, DB에서 닉네임과 이메일 변경
      erlangPrac_query:query(update_user,Idx,Email,Nickname),
      jsx:encode([{<<"result">>,<<"Change Data">>}]);
    _ ->
      %% 이메일이나 닉네임이 이미 존재하면, Exist Data 메세지 전송
      jsx:encode([{<<"result">>,<<"Exist Data">>}])
  end.

%% 대화보내기
dialog(RequestAtom,Data) when RequestAtom =:= dialog_send ->
  %% 방에 유저가 존재하는지여부 조회
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Room_idx = proplists:get_value(<<"room_idx">>,Data),
  Dialog = proplists:get_value(<<"dialog">>,Data),
  {_,_,_,Result,_} = erlangPrac_query:query(check_room,Room_idx,User_idx),
  case Result of
    []->
      %% 유저가 방에 존재하지 않을경우 , 아래 문자열 전달
      jsx:encode([{<<"result">>,<<"not exist user in room">>}]);
    _->
      %% 유저가 방에 존재할 경우, 다이얼로그에 추가
      erlangPrac_query:query(send_dialog,User_idx,Room_idx,Dialog),
      jsx:encode([{<<"result">>,<<"send dialog">>}])
  end;
%% 대화 조회 .
dialog(RequestAtom,Data) when RequestAtom =:= dialog_view->
  %% 방에 유저가 존재하는지여부 조회
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Room_idx = proplists:get_value(<<"room_idx">>,Data),
  Read_idx = proplists:get_value(<<"read_idx">>,Data),
  {_,_,_,Result,_} = erlangPrac_query:query(check_room,Room_idx,User_idx),
  case Result of
    []->
      %% 유저가 방에 존재하지 않을경우 , 아래 문자열 전달
      jsx:encode([{<<"result">>,<<"not exist user in room">>}]);
    _->
      %% 현재까지 읽은 dialog idx 를 확인한 후에 그 이후의 데이터에 대해 읽어옴
      DialogResult = erlangPrac_query:query(view_dialog,Room_idx,User_idx,Read_idx),
      io:format(<<"view Dialog ~n">>),
      jsx:encode(emysql_util:as_json(DialogResult))
  end.

%% 친구 신청
friend(RequestAtom,Data) when RequestAtom =:= request->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  erlangPrac_query:query(friend_request,User_idx,Target_idx),
  jsx:encode([{<<"result">>,<<"friend request">>}]);
%% 친구 수락 / 거절 / 대기
friend(RequestAtom,Data) when RequestAtom =:= answer->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  Answer = proplists:get_value(<<"answer">>,Data),
  erlangPrac_query:query(friend_answer,User_idx,Target_idx,Answer),
  jsx:encode([{<<"result">>,<<"aswer . state change">>}]);
%% 친구 리스트 보기
friend(RequestAtom,Data) when RequestAtom =:= view->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  jsx:encode(emysql_util:as_json(erlangPrac_query:query(friend_view,User_idx)));
%% 친구 요청 리스트 보기
friend(RequestAtom,Data) when RequestAtom =:= view_request->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  jsx:encode(emysql_util:as_json(erlangPrac_query:query(friend_view_request,User_idx)));
friend(RequestAtom,_)->
  jsx:encode([{"result","error request"},{"request",RequestAtom}]).
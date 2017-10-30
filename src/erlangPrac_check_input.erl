%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. 10월 2017 오후 12:44
%%%-------------------------------------------------------------------
-module(erlangPrac_check_input).
-author("Twinny-KJH").

%% API
-export([check_input/2]).

%% 유저 가입 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= user_register->
  Name = proplists:is_defined(<<"name">>,Data),
  Email = proplists:is_defined(<<"email">>,Data),
  Nickname = proplists:is_defined(<<"nickname">>,Data),
  if Name == false ->
    jsx:encode([{<<"result">>,<<"name is not exist">>}]);
    Email == false->
      jsx:encode([{<<"result">>,<<"email is not exist">>}]);
    Nickname == false->
      jsx:encode([{<<"result">>,<<"nickname is not exist">>}]);
    true ->true
  end;
%% 유저 정보변경 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= dialog_view->
  User_idx = proplists:is_defined(<<"user_idx">>,Data),
  Email = proplists:is_defined(<<"email">>,Data),
  Nickname = proplists:is_defined(<<"nickname">>,Data),
  if User_idx == false ->
    jsx:encode([{<<"result">>,<<"user_idx is not exist">>}]);
    Email == false->
      jsx:encode([{<<"result">>,<<"email is not exist">>}]);
    Nickname == false->
      jsx:encode([{<<"result">>,<<"nickname is not exist">>}]);
    true ->true
  end;
%% 대화조회 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= dialog_view->
  User_idx = proplists:is_defined(<<"user_idx">>,Data),
  Room_idx = proplists:is_defined(<<"room_idx">>,Data),
  Read_idx = proplists:is_defined(<<"read_idx">>,Data),
  if User_idx == false ->
    jsx:encode([{<<"result">>,<<"user_idx is not exist">>}]);
    Room_idx == false->
      jsx:encode([{<<"result">>,<<"room_idx is not exist">>}]);
    Read_idx == false->
      jsx:encode([{<<"result">>,<<"read_idx is not exist">>}]);
    true ->true
  end;
%% 대화보내기 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= dialog_send->
  User_idx = proplists:is_defined(<<"user_idx">>,Data),
  Room_idx = proplists:is_defined(<<"room_idx">>,Data),
  Dialog = proplists:is_defined(<<"dialog">>,Data),
  if User_idx == false ->
    jsx:encode([{<<"result">>,<<"user_idx is not exist">>}]);
    Room_idx == false->
      jsx:encode([{<<"result">>,<<"room_idx is not exist">>}]);
    Dialog == false->
      jsx:encode([{<<"result">>,<<"dialog is not exist">>}]);
    true ->true
  end;

%% 친구관련
%% 친구요청 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= friend_request->
  User_idx = proplists:is_defined(<<"user_idx">>,Data),
  Target_idx = proplists:is_defined(<<"target_idx">>,Data),
  if User_idx == false ->
    jsx:encode([{<<"result">>,<<"user_idx is not exist">>}]);
    Target_idx == false->
      jsx:encode([{<<"result">>,<<"room_idx is not exist">>}]);
    true ->true
  end;
%% 친구요청 응답 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= friend_answer->
  User_idx = proplists:is_defined(<<"user_idx">>,Data),
  Target_idx = proplists:is_defined(<<"target_idx">>,Data),
  Answer = proplists:is_defined(<<"answer">>,Data),
  if User_idx == false ->
    jsx:encode([{<<"result">>,<<"user_idx is not exist">>}]);
    Target_idx == false->
      jsx:encode([{<<"result">>,<<"target_idx is not exist">>}]);
    Answer == false->
      jsx:encode([{<<"result">>,<<"answer is not exist">>}]);
    true ->true
  end;
%% 친구목록보기 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= friend_view->
  User_idx = proplists:is_defined(<<"user_idx">>,Data),
  if User_idx == false ->
    jsx:encode([{<<"result">>,<<"user_idx is not exist">>}]);
    true ->true
  end;
%% 친구요청목록보기 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= friend_view_request->
  User_idx = proplists:is_defined(<<"user_idx">>,Data),
  if User_idx == false ->
    jsx:encode([{<<"result">>,<<"user_idx is not exist">>}]);
    true ->true
  end
.

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
-export([user_register/1, user_update/1,
  dialog_send/1, dialog_view/1,
  friend_add/1,friend_remove/1,friend_view/1, friend_suggest_view/1,friend_add_favorites/1,friend_remove_favorites/1,friend_favorites_name_update/1,friend_name_update/1,friend_favorites_move/1]).
%% proplists:is_defined(key,list)
%% 유저 가입시키기
user_register(Data) ->
  % 닉네임과 이메일 중복체크
  Name=proplists:get_value(<<"name">>,Data),
  Email=proplists:get_value(<<"email">>,Data),
  Nickname=proplists:get_value(<<"nickname">>,Data),
  {_,_,_,Result,_} =  erlangPrac_query:query(check_duplicate,Nickname,Email),
  case Result of
    [] ->
      % 디비에 데이터 추가.
      erlangPrac_query:query(register_user,Name,Email,Nickname),
      {ok,jsx:encode([{<<"result">>,<<"Register">>}])};
    _ ->
      % 중복되므로, Duplicate 메세지 전달
      {ok,jsx:encode([{<<"result">>,<<"Duplicate">>}])}
  end.

%% 유저 정보변경
user_update(Data)->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Email = proplists:get_value(<<"email">>,Data),
  Nickname = proplists:get_value(<<"nickname">>,Data),
  %% 중복닉네임 , 이메일 체크,
  %% 성공여부 반환
  {_,_,_,Result,_} = erlangPrac_query:query(check_duplicate,Nickname,Email),
  case Result of
    [] ->
      %% 이메일이나 닉네임이 중복되지 않으면, DB에서 닉네임과 이메일 변경
      erlangPrac_query:query(update_user, User_idx,Email,Nickname),
      {ok,jsx:encode([{<<"result">>,<<"Change Data">>}])};
    _ ->
      %% 이메일이나 닉네임이 이미 존재하면, Exist Data 메세지 전송
      {ok,jsx:encode([{<<"result">>,<<"Exist Data">>}])}
  end.

%% 대화보내기
dialog_send(Data) ->
  % 방에 유저가 존재하는지여부 조회
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Room_idx = proplists:get_value(<<"room_idx">>,Data),
  Dialog = proplists:get_value(<<"dialog">>,Data),
  {_,_,_,Result,_} = erlangPrac_query:query(check_room,Room_idx,User_idx),
  case Result of
    []->
      %% 유저가 방에 존재하지 않을경우 , 아래 문자열 전달
      {error,jsx:encode([{<<"result">>,<<"not exist user in room">>}])};
    _->
      %% 유저가 방에 존재할 경우, 다이얼로그에 추가
      erlangPrac_query:query(send_dialog,User_idx,Room_idx,Dialog),
      {ok,jsx:encode([{<<"result">>,<<"send dialog">>}])}
  end.
%% 대화 조회 .
dialog_view(Data) ->
  % 방에 유저가 존재하는지여부 조회
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Room_idx = proplists:get_value(<<"room_idx">>,Data),
  Read_idx = proplists:get_value(<<"read_idx">>,Data),
  {_,_,_,Result,_} = erlangPrac_query:query(check_room,Room_idx,User_idx),
  case Result of
    []->
      % 유저가 방에 존재하지 않을경우 , 아래 문자열 전달
      {error,jsx:encode([{<<"result">>,<<"not exist user in room">>}])};
    _->
      % 현재까지 읽은 dialog idx 를 확인한 후에 그 이후의 데이터에 대해 읽어옴
      DialogResult = erlangPrac_query:query(view_dialog,Room_idx,User_idx,Read_idx),
      io:format(<<"view Dialog ~n">>),
      {ok,jsx:encode(emysql_util:as_json(DialogResult))}
  end.

%% 친구 신청
friend_add(Data)->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  erlangPrac_query:query(friend_add,User_idx,Target_idx),
  {ok,jsx:encode([{<<"result">>,<<"friend add">>}])}.
friend_remove(Data)->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  erlangPrac_query:query(friend_remove,User_idx,Target_idx),
  {ok,jsx:encode([{<<"result">>,<<"friend remove">>}])}.
%% 친구 리스트 보기
friend_view(Data)->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  {ok,jsx:encode(emysql_util:as_json(erlangPrac_query:query(friend_view,User_idx)))}.
%% 친구 요청 리스트 보기
friend_suggest_view(Data)->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  {ok,jsx:encode(emysql_util:as_json(erlangPrac_query:query(friend_suggest_view,User_idx)))}.

friend_add_favorites(Data)->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  Favorites_idx = proplists:get_value(<<"favorites_idx">>,Data),
  erlangPrac_query:query(friend_add_favorites,Favorites_idx,User_idx,Target_idx),
  {ok,jsx:encode([{<<"result">>,<<"add friends">>}])}.

friend_remove_favorites(Data)->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  erlangPrac_query:query(friend_remove_favorites,User_idx,Target_idx),
  {ok,jsx:encode([{<<"result">>,<<"remove friends">>}])}.

friend_name_update(Data)->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  Change_name = proplists:get_value(<<"change_name">>,Data),
  erlangPrac_query:query(friend_name_update,User_idx,Target_idx,Change_name),
  {ok,jsx:encode([{<<"result">>,<<"update friends name">>}])}.

friend_favorites_name_update(Data)->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Favorites_name = proplists:get_value(<<"favorites_name">>,Data),
  Favorites_idx = proplists:get_value(<<"favorites_idx">>,Data),
  erlangPrac_query:query(friend_favorites_name_update,User_idx,Favorites_name,Favorites_idx),
  {ok,jsx:encode([{<<"result">>,<<"update friends favorites name">>}])}.

friend_favorites_move(Data)->
  User_idx = proplists:get_value(<<"user_idx">>,Data),
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  Favorites_idx = proplists:get_value(<<"favorites_idx">>,Data),
  erlangPrac_query:query(friend_favorites_move,User_idx,Target_idx,Favorites_idx),
  {ok,jsx:encode([{<<"result">>,<<"update friends favorites name">>}])}.

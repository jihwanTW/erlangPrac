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
-export([user_register/1,user_withdrawal/1, user_update/1,user_login/1,user_logout/1,user_info/1,user_room_invite/1,user_room_leave/1]).

-export([dialog_send/1, dialog_view/1]).

-export([friend_add/1,friend_remove/1,friend_view/1, friend_suggest_view/1,friend_add_favorites/1,friend_remove_favorites/1,friend_favorites_name_update/1,friend_name_update/1,friend_favorites_move/1]).

-include("sql_result_records.hrl").

%% 유저 가입시키기
user_register(Data) ->
  % 닉네임과 이메일 중복체크
  Name=proplists:get_value(<<"name">>,Data),
  Email=proplists:get_value(<<"email">>,Data),
  Nickname=proplists:get_value(<<"nickname">>,Data),
  % 중복검사
  Result = erlangPrac_mysql_query:query(check_duplicate,Nickname,Email),
  case Result#result_packet.rows of
    [] ->
      % 디비에 데이터 추가.
      erlangPrac_mysql_query:query(register_user,Name,Email,Nickname),
      {ok,jsx:encode([{<<"result">>,<<"Register">>}])};
    _ ->
      % 중복되므로, Duplicate 메세지 전달
      {ok,jsx:encode([{<<"result">>,<<"Duplicate">>}])}
  end.
%% 회원 탈퇴
user_withdrawal({User_idx,_Data})->
  % 현재 들어가있는 room_idx 모두 가져옴
  Room_lists = emysql_util:as_json(erlangPrac_mysql_query:query(all_room,User_idx)),
  % 해당 room_idx 를 기반으로 하여 모든 방에있는 읽음카운트를 올림
  View_all_dialog = fun(Room_list)-> erlangPrac_mysql_query:query(view_dialog,proplists:get_value(<<"room_idx">>,Room_list),User_idx,0)
                    end,
  lists:map(View_all_dialog, Room_lists),
  % 해당방들을 나가고 읽음 카운트 삭제
  Leave_all_room = fun(Room_list)->
    erlangPrac_mysql_query:query(user_room_leave, User_idx,proplists:get_value(<<"room_idx">>,Room_list))
                    end,
  lists:map(Leave_all_room, Room_lists),
  % 미구현 동작 ~
  % 일정삭제 및 공유된정보 삭제

  % 회원 유저정보를 remove = true 로 바꿈.
  RemoveResult = erlangPrac_mysql_query:query(user_withdrawal,User_idx),
  {ok,jsx:encode([{<<"result">>,RemoveResult#ok_packet.affected_rows}])}
.

%% 유저 로그인
user_login(Data)->
  User_id = proplists:get_value(<<"user_id">>,Data),
  %% 아이디 존재여부 체크
  %% 성공여부 반환
  Result = emysql_util:as_json(erlangPrac_mysql_query:query(user_login, User_id)),
  case Result of
    []->
      {error,jsx:encode([{<<"result">>,<<"id is not exist">>}])};
    _->
      % create session key
      % update session key
      [Result1|_]= Result,
      User_idx = proplists:get_value(<<"idx">>,Result1),
      {ok,Session} = erlangPrac_session:insert({User_id,User_idx}),
      % return session key
      {ok,jsx:encode([{<<"session">>,Session}])}
  end
.

%% 유저 정보변경
user_update({User_idx,Data})->
  Email = proplists:get_value(<<"email">>,Data),
  Nickname = proplists:get_value(<<"nickname">>,Data),
  %% 중복닉네임 , 이메일 체크,
  %% 성공여부 반환
  Result = erlangPrac_mysql_query:query(check_duplicate,Nickname,Email),
  case Result#result_packet.rows of
    [] ->
      %% 이메일이나 닉네임이 중복되지 않으면, DB에서 닉네임과 이메일 변경
      erlangPrac_mysql_query:query(update_user, User_idx,Email,Nickname),
      {ok,jsx:encode([{<<"result">>,<<"Change Data">>}])};
    _ ->
      %% 이메일이나 닉네임이 이미 존재하면, Exist Data 메세지 전송
      {ok,jsx:encode([{<<"result">>,<<"Exist Data">>}])}
  end.


%% 유저 로그아웃
%%Result#ok_packet.affected_rows
user_logout({_,Data})->
  Session = proplists:get_value(<<"session">>,Data),
  erlangPrac_session:delete(Session)
  .
%% 유저 정보보기
user_info({_,Data})->
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  {ok,jsx:encode(erlangPrac_mysql_query:query(user_info, Target_idx))}
  .

%% 방 나가기 및 읽음카운트 삭제
user_room_leave({User_idx,Data})->
  case dialog_view({User_idx,Data}) of
    {ok,_}->
      % 해당방에서 유저번호 삭제
      Room_idx = proplists:get_value(<<"room_idx">>,Data),
      erlangPrac_mysql_query:query(user_room_leave, User_idx,Room_idx),
      {ok,jsx:encode([{<<"result">>,<<"leave room">>}])};
    {error,Result}->
      {error,Result}
  end
.

user_room_invite({User_idx,Data})->
  % 피초대자
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  % 방번호 인자로 값을 넘겨주지 않았으면 랜덤값을 받아옴
  Room_idx = proplists:get_value(<<"room_idx">>,Data, utils:generate_random_int()),
  %% 초대하는 유저가 방에 존재하는지 여부 조회
  Result = erlangPrac_mysql_query:query(check_room,Room_idx,User_idx),
  case Result#result_packet.rows of
    []->
      io:format("room make ~n"),
      % 방에 존재하지 않으므로, 새로운 방을 만듬
      erlangPrac_mysql_query:query(room_make,Room_idx,User_idx,Target_idx),
      {ok,jsx:encode([{<<"room_idx">>,Room_idx}])};
    _->
      io:format("room invite ~n"),
      erlangPrac_mysql_query:query(room_invite,Room_idx,Target_idx),
      {ok,jsx:encode([{<<"room_idx">>,Room_idx}])}
  end
.

%% 대화보내기
dialog_send({User_idx,Data}) ->
  % 방에 유저가 존재하는지여부 조회
  Room_idx = proplists:get_value(<<"room_idx">>,Data,0),
  Dialog = proplists:get_value(<<"dialog">>,Data),
  Result = erlangPrac_mysql_query:query(check_room,Room_idx,User_idx),
  case Result#result_packet.rows of
    []->
      case proplists:is_defined(<<"target_idx">>,Data) of
        true->
          Target_idx = proplists:get_value(<<"target_idx">>,Data),
          Result1 = erlangPrac_mysql_query:query(check_personal_room,User_idx,Target_idx),
          case Result1#result_packet.rows of
            []->
              % 만약, 방이 없고, target_idx 가 같이 넘어온다면, 개인대 개인으로 새롭게 채팅을 보내는 것으로 간주하고 방생성.
              {ok,Room_idx2} = user_room_invite({User_idx,Data}),
              Room_idx3 = jsx:decode(Room_idx2),
              erlangPrac_mysql_query:query(send_dialog,User_idx,proplists:get_value(<<"room_idx">>,Room_idx3),Dialog),
              {ok,jsx:encode([{<<"result">>,<<"send dialog - make room">>}])};
            _->
              % 혹시 방이 존재하는데, 유저가 해당방을 나건거라면, 해당방 생성을 하지 않고 채팅을 보냄.
              [Result2|_T] = emysql_util:as_json(Result1),
              Room_idx2 = proplists:get_value(<<"room_idx">>,Result2),
              erlangPrac_mysql_query:query(send_dialog,User_idx,Room_idx2,Dialog),
              {ok,jsx:encode([{<<"result">>,<<"send dialog to personal">>}])}
          end;
        false ->
          %% 유저가 방에 존재하지 않을경우 , 아래 문자열 전달
          {error,jsx:encode([{<<"result">>,<<"not exist user in room">>}])}
      end;
    _->
      %% 유저가 방에 존재할 경우, 다이얼로그에 추가
      erlangPrac_mysql_query:query(send_dialog,User_idx,Room_idx,Dialog),
      {ok,jsx:encode([{<<"result">>,<<"send dialog">>}])}
  end.
%% 대화 조회 .
dialog_view({User_idx,Data}) ->
  % 방에 유저가 존재하는지여부 조회
  Room_idx = proplists:get_value(<<"room_idx">>,Data),
  Read_idx = proplists:get_value(<<"read_idx">>,Data,0),
  Result = erlangPrac_mysql_query:query(check_room,Room_idx,User_idx),
  case Result#result_packet.rows of
    []->
      % 유저가 방에 존재하지 않을경우 , 아래 문자열 전달
      {error,jsx:encode([{<<"result">>,<<"not exist user in room">>}])};
    _->
      % 현재까지 읽은 dialog idx 를 확인한 후에 그 이후의 데이터에 대해 읽어옴
      DialogResult = erlangPrac_mysql_query:query(view_dialog,Room_idx,User_idx,Read_idx),
      {ok,jsx:encode(emysql_util:as_json(DialogResult))}
  end.

%% 친구 신청
friend_add({User_idx,Data})->
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  erlangPrac_mysql_query:query(friend_add,User_idx,Target_idx),
  {ok,jsx:encode([{<<"result">>,<<"friend add">>}])}.
friend_remove({User_idx,Data})->
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  erlangPrac_mysql_query:query(friend_remove,User_idx,Target_idx),
  {ok,jsx:encode([{<<"result">>,<<"friend remove">>}])}.
%% 친구 리스트 보기
friend_view({User_idx,_})->
  {ok,jsx:encode(emysql_util:as_json(erlangPrac_mysql_query:query(friend_view,User_idx)))}.
%% 친구가 되어있는 추천친구 확인하기
friend_suggest_view({User_idx,_})->
  {ok,jsx:encode(emysql_util:as_json(erlangPrac_mysql_query:query(friend_suggest_view,User_idx)))}.

friend_add_favorites({User_idx,Data})->
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  Favorites_idx = proplists:get_value(<<"favorites_idx">>,Data),
  erlangPrac_mysql_query:query(friend_add_favorites,Favorites_idx,User_idx,Target_idx),
  {ok,jsx:encode([{<<"result">>,<<"add friends">>}])}.

friend_remove_favorites({User_idx,Data})->
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  erlangPrac_mysql_query:query(friend_remove_favorites,User_idx,Target_idx),
  {ok,jsx:encode([{<<"result">>,<<"remove friends">>}])}.

friend_name_update({User_idx,Data})->
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  Change_name = proplists:get_value(<<"change_name">>,Data),
  erlangPrac_mysql_query:query(friend_name_update,User_idx,Target_idx,Change_name),
  {ok,jsx:encode([{<<"result">>,<<"update friends name">>}])}.

friend_favorites_name_update({User_idx,Data})->
  Favorites_name = proplists:get_value(<<"favorites_name">>,Data),
  Favorites_idx = proplists:get_value(<<"favorites_idx">>,Data),
  erlangPrac_mysql_query:query(friend_favorites_name_update,User_idx,Favorites_name,Favorites_idx),
  {ok,jsx:encode([{<<"result">>,<<"update friends favorites name">>}])}.

friend_favorites_move({User_idx,Data})->
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  Favorites_idx = proplists:get_value(<<"favorites_idx">>,Data),
  erlangPrac_mysql_query:query(friend_favorites_move,User_idx,Target_idx,Favorites_idx),
  {ok,jsx:encode([{<<"result">>,<<"update friends favorites name">>}])}.



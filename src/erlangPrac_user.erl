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
-export([user_register/1, user_update/1,user_login/1,user_logout/1]).

-export([dialog_send/1, dialog_view/1]).

-export([friend_add/1,friend_remove/1,friend_view/1, friend_suggest_view/1,friend_add_favorites/1,friend_remove_favorites/1,friend_favorites_name_update/1,friend_name_update/1,friend_favorites_move/1]).

-record(ok_packet, {seq_num, affected_rows, insert_id, status, warning_count, msg}).

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

%% 유저 로그인
user_login(Data)->
  User_id = proplists:get_value(<<"user_id">>,Data),
  %% 아이디 존재여부 체크
  %% 성공여부 반환
  % 이 방식으로 하면 여러개의 결과값이 조회될 경우 에러가 발생할수 있으니, 검색 결과가 단일성이 보장되는 쿼리문에만 사용할것!
  [Result] = emysql_util:as_json(erlangPrac_query:query(user_login, User_id)),
  case Result of
    []->
      {error,jsx:encode([{<<"result">>,<<"id is not exist">>}])};
    _->
      % create session key
      Session = new_session(User_id),
      % update session key
      User_idx = proplists:get_value(<<"idx">>,Result),
      erlangPrac_query:query(session_update,User_idx,Session),
      % return session key
      {ok,jsx:encode([{<<"session">>,Session}])}
  end
.

%% 유저 정보변경
user_update({SessionData,Data})->
  User_idx = proplists:get_value(<<"idx">>,SessionData),
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


%% 유저 로그아웃
user_logout({SessionData,Data})->
  User_idx = proplists:get_value(<<"idx">>,SessionData),
  Result = erlangPrac_query:query(session_remove,User_idx),
  case Result#ok_packet.affected_rows of
    0->
      {error,jsx:encode([{<<"reseult">>,<<"user idx is not exist or already session destroy">>}])};
    _->
      {ok,jsx:encode([{<<"result">>,<<"session destroy">>}])}
  end
  .

%% 대화보내기
dialog_send({SessionData,Data}) ->
  % 방에 유저가 존재하는지여부 조회
  User_idx = proplists:get_value(<<"idx">>,SessionData),
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
dialog_view({SessionData,Data}) ->
  % 방에 유저가 존재하는지여부 조회
  User_idx = proplists:get_value(<<"idx">>,SessionData),
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
friend_add({SessionData,Data})->
  User_idx = proplists:get_value(<<"idx">>,SessionData),
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  erlangPrac_query:query(friend_add,User_idx,Target_idx),
  {ok,jsx:encode([{<<"result">>,<<"friend add">>}])}.
friend_remove({SessionData,Data})->
  User_idx = proplists:get_value(<<"idx">>,SessionData),
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  erlangPrac_query:query(friend_remove,User_idx,Target_idx),
  {ok,jsx:encode([{<<"result">>,<<"friend remove">>}])}.
%% 친구 리스트 보기
friend_view({SessionData,Data})->
  User_idx = proplists:get_value(<<"idx">>,SessionData),
  {ok,jsx:encode(emysql_util:as_json(erlangPrac_query:query(friend_view,User_idx)))}.
%% 친구 요청 리스트 보기
friend_suggest_view({SessionData,Data})->
  User_idx = proplists:get_value(<<"idx">>,SessionData),
  {ok,jsx:encode(emysql_util:as_json(erlangPrac_query:query(friend_suggest_view,User_idx)))}.

friend_add_favorites({SessionData,Data})->
  User_idx = proplists:get_value(<<"idx">>,SessionData),
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  Favorites_idx = proplists:get_value(<<"favorites_idx">>,Data),
  erlangPrac_query:query(friend_add_favorites,Favorites_idx,User_idx,Target_idx),
  {ok,jsx:encode([{<<"result">>,<<"add friends">>}])}.

friend_remove_favorites({SessionData,Data})->
  User_idx = proplists:get_value(<<"idx">>,SessionData),
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  erlangPrac_query:query(friend_remove_favorites,User_idx,Target_idx),
  {ok,jsx:encode([{<<"result">>,<<"remove friends">>}])}.

friend_name_update({SessionData,Data})->
  User_idx = proplists:get_value(<<"idx">>,SessionData),
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  Change_name = proplists:get_value(<<"change_name">>,Data),
  erlangPrac_query:query(friend_name_update,User_idx,Target_idx,Change_name),
  {ok,jsx:encode([{<<"result">>,<<"update friends name">>}])}.

friend_favorites_name_update({SessionData,Data})->
  User_idx = proplists:get_value(<<"idx">>,SessionData),
  Favorites_name = proplists:get_value(<<"favorites_name">>,Data),
  Favorites_idx = proplists:get_value(<<"favorites_idx">>,Data),
  erlangPrac_query:query(friend_favorites_name_update,User_idx,Favorites_name,Favorites_idx),
  {ok,jsx:encode([{<<"result">>,<<"update friends favorites name">>}])}.

friend_favorites_move({SessionData,Data})->
  User_idx = proplists:get_value(<<"idx">>,SessionData),
  Target_idx = proplists:get_value(<<"target_idx">>,Data),
  Favorites_idx = proplists:get_value(<<"favorites_idx">>,Data),
  erlangPrac_query:query(friend_favorites_move,User_idx,Target_idx,Favorites_idx),
  {ok,jsx:encode([{<<"result">>,<<"update friends favorites name">>}])}.


%% 세션 생성
new_session(Id)->
  random:seed(now()),
  Num = random:uniform(10000),

  Hash=erlang:phash2(Id),

  List = io_lib:format("~.16B~.16B",[Hash,Num]),
  list_to_binary(lists:append(List))
  .


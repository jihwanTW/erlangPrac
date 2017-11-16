%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 10월 2017 오후 4:10
%%%-------------------------------------------------------------------
-module(erlangPrac_mysql_query).
-author("Twinny-KJH").

%% API
-export([query/2,query/3,query/4,query/5]).

%% Name,Email,Nickname,Room_idx,User_idx,Read_idx

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% query/2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 친구목록 조회
query(QueryType,User_idx) when QueryType =:= friend_view->
  SQL =
    "SELECT    *
     FROM      user
     JOIN      friend_list
     JOIN      favorites
     ON        user.idx = friend_list.friend_idx AND
               friend_list.favorites_idx = favorites.idx
     WHERE     friend_list.user_idx = ? AND
               ( favorites.idx = friend_list.favorites_idx OR friend_list.favorites_idx = 0 )
     ORDER BY  friend_list.favorites_idx DESC,
               friend_list.custom_name DESC ",
  emysql:prepare(friend_view, SQL),
  emysql:execute(chatting_db,friend_view,[User_idx]);
%% 친구가 되어있는 추천친구 확인하기
query(QueryType,User_idx) when QueryType =:= friend_suggest_view->
  emysql:prepare(friend_suggest_view,<<"SELECT * FROM user join friend_list on user.idx = friend_list.user_idx WHERE friend_list.friend_idx = ?">>),
  emysql:execute(chatting_db,friend_suggest_view,[User_idx]);
%% 유저정보 조회
query(QueryType,Target_idx) when QueryType =:= user_info->
  io:format("info : ~p ~n",[Target_idx]),
  Redis_result = erlangPrac_query_redis:get_user(Target_idx),
  case Redis_result of
    {ok,undefined}->
      % redis에 등록이 안되있으므로 db조회
      emysql:prepare(user_info,<<"SELECT * FROM user WHERE idx = ?">>),
      Mysql_result = emysql_util:as_json(emysql:execute(chatting_db,user_info,[Target_idx])),
      %redis에 등록
      case Mysql_result of
        []->
          {ok,jsx:encode([{<<"result">>,<<"undefined value">>}])};
        _->
          erlangPrac_query_redis:insert(Mysql_result),
          %db 조회결과 반환
          io:format("check in mysql ~p ~n",[Redis_result]),
          [Result] = Mysql_result,
          {ok,jsx:encode(Result)}
      end;
    {ok,_}->
      io:format("check in redis ~p ~n",[Redis_result]),
      {ok,RedisVal}=Redis_result,
      {ok,jsx:encode(erlangPrac_customJson:redis2json(RedisVal))};
    _->
      io:format("error this point ~p ~n",[Redis_result]),
      {error,jsx:encode([{<<"result">>,<<"error in user_info . case Redis_result : _">>}])}
  end;
%% 로그인 체크
%% redis로 활용불가. 최초로 접속하는부분임.
query(QueryType, User_id) when QueryType =:= user_login->
  emysql:prepare(user_login,<<"SELECT * FROM user WHERE id = ?">>),
  Result = emysql:execute(chatting_db,user_login,[User_id]),
  erlangPrac_query_redis:login(emysql_util:as_json(Result)),
  Result;
query(QueryType,_)->
  {error,jsx:encode([{<<"result">>,<<"query type error">>},{<<"type">>},{QueryType}])}
.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% query/3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 방에 유저가 존재하는지 조회
query(QueryType,Room_idx,User_idx) when QueryType =:= check_room->
  emysql:prepare(check_room,<<"SELECT * FROM room_user WHERE room_idx= ? and user_idx = ?">>),
  io:format("user idx = ~p ~n",[User_idx]),
  emysql:execute(chatting_db,check_room,[Room_idx,User_idx]);
%% 닉네임과 이메일 중복 조회
%% redis 로 활용 불가. 검색범위가 너무 넓음.
query(QueryType,Nickname,Email) when QueryType =:= check_duplicate->
  emysql:prepare(check_user,<<"SELECT * FROM user WHERE email=? or nickname=? ">>),
  emysql:execute(chatting_db,check_user,[Email,Nickname]);
%% 친구 추가
query(QueryType,User_idx,Target_idx) when QueryType =:= friend_add->
  emysql:prepare(friend_add,<<"INSERT INTO friend_list (friend_list.user_idx,friend_list.friend_idx,friend_list.custom_name) values (?, ?, (SELECT nickname FROM user WHERE idx = ?)) ">>),
  emysql:execute(chatting_db,friend_add,[User_idx,Target_idx,Target_idx]);
%% 친구 삭제
query(QueryType,User_idx,Target_idx) when QueryType =:= friend_remove->
  emysql:prepare(friend_remove,<<"DELETE FROM friend_list WHERE user_idx = ? and friend_idx = ?">>),
  emysql:execute(chatting_db,friend_remove,[User_idx,Target_idx]);
%% 친구 즐겨찾기 삭제
query(QueryType,User_idx,Target_idx) when QueryType =:= friend_remove_favorites->
  emysql:prepare(remove_favorites,<<"UPDATE friend_list SET favorites_idx = ? WHERE user_idx=? and friend_idx= ?">>),
  emysql:execute(chatting_db,remove_favorites,[0,User_idx,Target_idx]);
query(QueryType,_,_)->
  {error,jsx:encode([{<<"result">>,<<"query type error">>},{<<"type">>},{QueryType}])}
.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% query/4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 기존에 대화가 존재할경우, 읽음 카운트만 조회 .
%% 대화 조회 및 읽음 카운트 감소
query(QueryType,Room_idx,User_idx,Read_idx) when QueryType =:= view_dialog->
  %% 읽음 카운트 감소하기 위해 현재까지 읽은 대화 idx를 가져온다.
  emysql:prepare(view_read_dialog_idx,<<"SELECT dialog_idx FROM read_dialog_idx WHERE room_idx=? and user_idx = ?">>),
  Result =emysql_util:as_json(emysql:execute(chatting_db,view_read_dialog_idx,[Room_idx,User_idx])),

  %% 읽음 카운트에서 이후의 대화에 대해 카운트를 감소하기 위해, 가장 높은값의 idx를 가져온다.
  emysql:prepare(update_read_idx,<<"SELECT idx FROM dialog WHERE room_idx=? order by idx desc limit 0,1">>),
  [H2|_] = emysql_util:as_json(emysql:execute(chatting_db,update_read_idx,[Room_idx])),
  LastDialogIdx = proplists:get_value(<<"idx">>,H2),
  case Result of
  []->
    %% Result가 비어있는 List라면, 읽음카운트 DB에 값을 새로 추가.
    emysql:prepare(insert_dialog_read,<<"INSERT INTO read_dialog_idx (room_idx,user_idx,dialog_idx) values (?, ?, ?)">>),
    emysql:execute(chatting_db,insert_dialog_read,[Room_idx,User_idx,LastDialogIdx]);
  _->
    %% Result가 비어있는 LIST가 아니라면, 카운트 감소된부분 갱신
    [H|_] = Result,
    emysql:prepare(update_dialog_read,<<"UPDATE dialog SET unread_user_num=unread_user_num-1 WHERE idx > ? and room_idx = ?">>),
    emysql:execute(chatting_db,update_dialog_read,[proplists:get_value(<<"dialog_idx">>,H),Room_idx]),
    %% 현재까지 카운트 감소된부분 갱신
    emysql:prepare(update_dialog_read,<<"UPDATE read_dialog_idx SET dialog_idx = ?  WHERE room_idx =  ? and user_idx = ?">>),
    emysql:execute(chatting_db,update_dialog_read,[LastDialogIdx,Room_idx,User_idx])
  end,
  %% 대화 조회 결과값 전송
  emysql:prepare(view_dialog,<<"SELECT * FROM dialog WHERE room_idx=? and idx > ? limit 0,50">>),
  emysql:execute(chatting_db,view_dialog,[Room_idx,Read_idx]);

%% 대화 전송 및 읽음 카운트 설정
query(QueryType,User_idx,Room_idx,Dialog) when QueryType =:= send_dialog->
  %% 대화방에 있는 유저수 조회
  emysql:prepare(check_user,<<"SELECT count(*) as cnt FROM room_user WHERE room_idx=? ">>),
  Result = emysql:execute(chatting_db,check_user,[Room_idx]),
  [H|_] = emysql_util:as_json(Result),
  Cnt = proplists:get_value(<<"cnt">>,H),
  %% 대화내용 DB에 삽입
  emysql:prepare(insert_dialog,<<"INSERT INTO dialog (room_idx,user_idx,user_dialog,date_time,unread_user_num) values(?, ?, ?,now(),?)">>),
  emysql:execute(chatting_db,insert_dialog,[Room_idx,User_idx,Dialog,Cnt]);

%% 회원가입
query(QueryType,Name,Email,Nickname) when QueryType =:= register_user->
  emysql:prepare(register_user,<<"INSERT INTO user (name,email,nickname,date_time,unread_user_num) values(?, ?, ?, now())">>),
  emysql:execute(chatting_db,register_user,[Name,Email,Nickname]);

%% 유저정보 업데이트
query(QueryType,User_idx,Email,Nickname) when QueryType =:= update_user->
  erlangPrac_query_redis:update({User_idx,Email,Nickname}),
  emysql:prepare(update_user,<<"UPDATE user SET email=?, nickname=? WHERE idx=?">>),
  emysql:execute(chatting_db,update_user,[Email,Nickname,User_idx]);

%% 친구 이름변경
query(QueryType, User_idx, Target_idx, Change_Name) when QueryType =:= friend_name_update->
  if Change_Name =:= <<"">> ->
    emysql:prepare(name_update,<<"UPDATE friend_list,user SET friend_list.custom_name=user.nickname WHERE friend_list.user_idx = ? and friend_list.friend_idx = ? and user.idx = ?">>),
    emysql:execute(chatting_db,name_update,[User_idx, Target_idx,User_idx]);
    true ->
      emysql:prepare(name_update,<<"UPDATE friend_list SET custom_name=? WHERE user_idx = ? and friend_idx = ?">>),
      emysql:execute(chatting_db,name_update,[Change_Name,User_idx, Target_idx])
    end;

%% 친구 즐겨찾기 추가 or 친구 즐겨찾기 그룹 옮기기
query(QueryType,User_idx,Target_idx,Favorites_idx) when QueryType =:= friend_add_favorites orelse QueryType =:= friend_favorites_move->
  emysql:prepare(add_favorites,<<"UPDATE friend_list SET favorites_idx = ? WHERE user_idx=? and friend_idx= ?">>),
  emysql:execute(chatting_db,add_favorites,[Favorites_idx,User_idx,Target_idx]);

%% 친구 즐겨찾기 이름변경
query(QueryType, User_idx, Change_Name,Favorites_idx) when QueryType =:= friend_favorites_name_update->
  % 바뀔 즐겨찾기이름 중복조회
  emysql:prepare(favorites_check_duplicate,<<"SELECT * FROM favorites WHERE favorites_name = ?">>),
  {_,_,_,Result,_} = emysql:execute(chatting_db,favorites_check_duplicate,[Change_Name]),
  case Result of
    []->
      % 바뀔 그룹명 insert
      emysql:prepare(favorites_name_insert,<<"INSERT INTO favorites (favorites_name) values (?)">>),
      emysql:execute(chatting_db,favorites_name_insert,[Change_Name]);
    _->
      true
  end,
  % 바뀔 그룹으로 update 해당 즐겨찾기 그룹 전체에대한 update
  emysql:prepare(favorites_name_update,<<"UPDATE friend_list,favorites SET friend_list.favorites_idx=favorites.idx WHERE friend_list.user_idx = ? and friend_list.favorites_idx = ? and favorites.favorites_name = ?">>),
  emysql:execute(chatting_db,favorites_name_update,[User_idx,Favorites_idx,Change_Name]);


query(QueryType,_,_,_)->
  {error,jsx:encode([{<<"result">>,<<"query type error">>},{<<"type">>},{QueryType}])}
.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%query 5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
query(QueryType,_,_,_,_)->
  {error,jsx:encode([{<<"result">>,<<"query type error">>},{<<"type">>},{QueryType}])}
.

%% prepare function 과 execute function 이 반복되고있다! 이걸 모듈화시키는게 괜찮은걸까 ?
%%execute_query(QueryType,Query,DataList) when is_atom(QueryType),is_binary(Query),is_list(DataList)->
%%  emysql:prepare(QueryType,Query),
%%  try emysql:execute(chatting_db,QueryType,DataList)
%%  catch
%%    throw:Why -> {500,jsx:encode([{"result",Why}])};
%%    exit:Why -> {500,jsx:encode([{"result",Why}])};
%%    error:Why -> {500,jsx:encode([{"result",Why}])}
%%  end
%%  ;
%%execute_query(QueryType,Query,DataList) ->
%%  io:format("error  : ~p ~n",[jsx:encode([{"result","query error"},{"query_type",QueryType},{"query",Query},{"data_list",DataList}])]),
%%  {500,jsx:encode([{"error","query error check server log!"}])}
%%.
%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 10월 2017 오전 12:48
%%%-------------------------------------------------------------------
-module(erlangPrac_app).
-author("Twinny-KJH").

-behaviour(application).

%% Application callbacks
-export([start/2,
  stop/1]).

%%%===================================================================
%%% Application callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called whenever an application is started using
%% application:start/[1,2], and should start the processes of the
%% application. If the application is structured according to the OTP
%% design principles as a supervision tree, this means starting the
%% top supervisor of the tree.
%%
%% @end
%%--------------------------------------------------------------------
-spec(start(StartType :: normal | {takeover, node()} | {failover, node()},
    StartArgs :: term()) ->
  {ok, pid()} |
  {ok, pid(), State :: term()} |
  {error, Reason :: term()}).
start(_StartType, _StartArgs) ->
  ok = application:start(crypto),
  ok = application:start(cowlib),
  ok = application:start(ranch),
  ok = application:start(cowboy),

  %% emysql 로딩
  crypto:start(),
  application:start(emysql),

  %% emysql DB pool 생성
  emysql:add_pool(
    chatting_db,
    [{size,1},
      {user,"root"},
      {password,"jhkim1020"},
      {database,"erlangprac_chattingdb"},
      {encoding,utf8}
    ]),

  %% Cowboy의 Router를 설정함
  Dispatch = cowboy_router:compile([
    { '_',[
      {"/:api/[:what/[:opt]]",erlangPrac_http,[]}
    ]}
  ]),
  %%실제로 소켓을 열고 서버를 구동하는 부분.
  { ok, _} = cowboy:start_http(
    http,
    100,
    [{port,80}],
    [{env,[{dispatch,Dispatch}]}]
  ),
  %% Code reloader 실행
  erlangPrac_reloader:start(),

  %% dets table 생성
  dets:open_file(users_list,[{type,set}]),

  case erlangPrac_sup:start_link() of
    {ok, Pid} ->
      {ok, Pid};
    Error ->
      Error
  end.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called whenever an application has stopped. It
%% is intended to be the opposite of Module:start/2 and should do
%% any necessary cleaning up. The return value is ignored.
%%
%% @end
%%--------------------------------------------------------------------
-spec(stop(State :: term()) -> term()).
stop(_State) ->
  ok.

%%%===================================================================
%%% Internal functions
%%%===================================================================

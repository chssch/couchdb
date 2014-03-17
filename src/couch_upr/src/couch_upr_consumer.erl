% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.

% This module is for parsing and encoding all the UPR commands that are needed
% by the indexer.
-module(couch_upr_consumer).

-export([parse_header/1, parse_snapshot_mutation/4, parse_snapshot_deletion/2,
    parse_failover_log/1, parse_stat/4]).
-export([encode_sasl_auth/2, encode_open_connection/2, encode_stream_request/6,
    encode_failover_log_request/2, encode_stat_request/3, encode_stream_close/2]).

-include_lib("couch_upr/include/couch_upr.hrl").
-include_lib("couch_upr/include/couch_upr_typespecs.hrl").


% TODO vmx 2013-08-22: Bad match error handling
-spec parse_header(<<_:192>>) ->
                          {atom(), size()} |
                          {atom(), upr_status(), request_id(), size()} |
                          {atom(), upr_status(), request_id(), size(),
                           size()} |
                          {atom(), partition_id(), request_id()} |
                          {atom(), partition_id(), request_id(), size()} |
                          {atom(), partition_id(), request_id(), size(),
                           size()} |
                          {atom(), partition_id(), request_id(), size(),
                           size(), uint64()} |
                          {atom(), partition_id(), request_id(), size(),
                           size(), size(), uint64()}.
parse_header(<<?UPR_MAGIC_RESPONSE,
               Opcode,
               KeyLength:?UPR_SIZES_KEY_LENGTH,
               _ExtraLength,
               0,
               Status:?UPR_SIZES_STATUS,
               BodyLength:?UPR_SIZES_BODY,
               RequestId:?UPR_SIZES_OPAQUE,
               _Cas:?UPR_SIZES_CAS>>) ->
    case Opcode of
    ?UPR_OPCODE_STREAM_REQUEST ->
        {stream_request, Status, RequestId, BodyLength};
    ?UPR_OPCODE_OPEN_CONNECTION ->
        {open_connection, RequestId};
    ?UPR_OPCODE_FAILOVER_LOG_REQUEST ->
        {failover_log, Status, RequestId, BodyLength};
    ?UPR_OPCODE_STATS ->
        {stats, Status, RequestId, BodyLength, KeyLength};
    ?UPR_OPCODE_SASL_AUTH ->
        {sasl_auth, Status, RequestId, BodyLength};
    ?UPR_OPCODE_STREAM_CLOSE ->
        {stream_close, Status, RequestId, BodyLength}
    end;
parse_header(<<?UPR_MAGIC_REQUEST,
               Opcode,
               KeyLength:?UPR_SIZES_KEY_LENGTH,
               ExtraLength,
               _DataType,
               PartId:?UPR_SIZES_PARTITION,
               BodyLength:?UPR_SIZES_BODY,
               RequestId:?UPR_SIZES_OPAQUE,
               Cas:?UPR_SIZES_CAS>>) ->
    case Opcode of
    ?UPR_OPCODE_STREAM_END ->
        {stream_end, PartId, RequestId, BodyLength};
    ?UPR_OPCODE_SNAPSHOT_MARKER ->
        {snapshot_marker, PartId, RequestId};
    ?UPR_OPCODE_MUTATION ->
        {snapshot_mutation, PartId, RequestId, KeyLength, BodyLength,
            ExtraLength, Cas};
    ?UPR_OPCODE_DELETION ->
        {snapshot_deletion, PartId, RequestId, KeyLength, BodyLength, Cas};
    ?UPR_OPCODE_EXPIRATION ->
        {snapshot_expiration, PartId, RequestId, KeyLength, BodyLength, Cas}
    end.

-spec parse_snapshot_mutation(size(), binary(), size(), size()) ->
                                     {snapshot_mutation, #mutation{}}.
parse_snapshot_mutation(KeyLength, Body, BodyLength, ExtraLength) ->
    <<Seq:?UPR_SIZES_BY_SEQ,
      RevSeq:?UPR_SIZES_REV_SEQ,
      Flags:?UPR_SIZES_FLAGS,
      Expiration:?UPR_SIZES_EXPIRATION,
      LockTime:?UPR_SIZES_LOCK,
      MetadataLength:?UPR_SIZES_METADATA_LENGTH,
      _Nru:?UPR_SIZES_NRU_LENGTH,
      Key:KeyLength/binary,
      Rest/binary>> = Body,
    ValueLength = BodyLength - ExtraLength - KeyLength - MetadataLength,
    <<Value:ValueLength/binary,
      Metadata:MetadataLength/binary>> = Rest,
    {snapshot_mutation, #mutation{
        seq = Seq,
        rev_seq = RevSeq,
        flags = Flags,
        expiration = Expiration,
        locktime = LockTime,
        key = Key,
        value = Value,
        metadata = Metadata
    }}.

-spec parse_snapshot_deletion(size(), binary()) ->
                                     {snapshot_deletion,
                                      {update_seq(), non_neg_integer(),
                                       binary(), binary()}}.
parse_snapshot_deletion(KeyLength, Body) ->
    % XXX vmx 2014-01-07: No metadata support for now. Make it so it breaks
    % once it's there.
    MetadataLength = 0,
    <<Seq:?UPR_SIZES_BY_SEQ,
      RevSeq:?UPR_SIZES_REV_SEQ,
      MetadataLength:?UPR_SIZES_METADATA_LENGTH,
      Key:KeyLength/binary,
      Metadata:MetadataLength/binary>> = Body,
    {snapshot_deletion, {Seq, RevSeq, Key, Metadata}}.


-spec parse_failover_log(binary(), partition_version()) ->
                                {ok, partition_version()}.
parse_failover_log(Body) ->
    parse_failover_log(Body, []).
parse_failover_log(<<>>, Acc) ->
    {ok, lists:reverse(Acc)};
parse_failover_log(<<PartUuid:?UPR_SIZES_PARTITION_UUID/integer,
                     PartSeq:?UPR_SIZES_BY_SEQ,
                     Rest/binary>>,
                   Acc) ->
    parse_failover_log(Rest, [{PartUuid, PartSeq}|Acc]).


-spec parse_stat(binary(), upr_status(), size(), size()) ->
                        {ok, {binary(), binary()}} |
                        {error, {upr_status(), binary()}}.
parse_stat(Body, Status, 0, _ValueLength) ->
    {error, {Status, Body}};
parse_stat(Body, ?UPR_STATUS_OK, KeyLength, ValueLength) ->
    <<Key:KeyLength/binary, Value:ValueLength/binary>> = Body,
    {ok, {Key, Value}}.


-spec encode_sasl_auth(binary(), request_id()) -> binary().
encode_sasl_auth(Bucket, RequestId) ->
    AuthType = <<"PLAIN">>,
    Body = <<AuthType/binary, $\0,
             Bucket/binary, $\0, $\0>>,

    KeyLength = byte_size(AuthType),
    BodyLength = byte_size(Body),
    ExtraLength = 0,

    Header = <<?UPR_MAGIC_REQUEST,
               ?UPR_OPCODE_SASL_AUTH,
               KeyLength:?UPR_SIZES_KEY_LENGTH,
               ExtraLength,
               0,
               0:?UPR_SIZES_PARTITION,
               BodyLength:?UPR_SIZES_BODY,
               RequestId:?UPR_SIZES_OPAQUE,
               0:?UPR_SIZES_CAS>>,
    <<Header/binary, Body/binary>>.

%UPR_OPEN command
%Field        (offset) (value)
%Magic        (0)    : 0x80
%Opcode       (1)    : 0x50
%Key length   (2,3)  : 0x0018
%Extra length (4)    : 0x08
%Data type    (5)    : 0x00
%Vbucket      (6,7)  : 0x0000
%Total body   (8-11) : 0x00000020
%Opaque       (12-15): 0x00000001
%CAS          (16-23): 0x0000000000000000
%  seqno      (24-27): 0x00000000
%  flags      (28-31): 0x00000000 (consumer)
%Key          (32-55): bucketstream vb[100-105]
-spec encode_open_connection(binary(), request_id()) -> binary().
encode_open_connection(Name, RequestId) ->
    Body = <<0:?UPR_SIZES_SEQNO,
             ?UPR_FLAG_PRODUCER:?UPR_SIZES_FLAGS,
             Name/binary>>,

    KeyLength = byte_size(Name),
    BodyLength = byte_size(Body),
    ExtraLength = BodyLength - KeyLength,

    Header = <<?UPR_MAGIC_REQUEST,
               ?UPR_OPCODE_OPEN_CONNECTION,
               KeyLength:?UPR_SIZES_KEY_LENGTH,
               ExtraLength,
               0,
               0:?UPR_SIZES_PARTITION,
               BodyLength:?UPR_SIZES_BODY,
               RequestId:?UPR_SIZES_OPAQUE,
               0:?UPR_SIZES_CAS>>,
    <<Header/binary, Body/binary>>.

%UPR_STREAM_REQ command
%Field        (offset) (value)
%Magic        (0)    : 0x80
%Opcode       (1)    : 0x53
%Key length   (2,3)  : 0x0000
%Extra length (4)    : 0x28
%Data type    (5)    : 0x00
%Vbucket      (6,7)  : 0x0000
%Total body   (8-11) : 0x00000028
%Opaque       (12-15): 0x00001000
%CAS          (16-23): 0x0000000000000000
%  flags      (24-27): 0x00000000
%  reserved   (28-31): 0x00000000
%  start seqno(32-39): 0x0000000000ffeedd
%  end seqno  (40-47): 0xffffffffffffffff
%  vb UUID    (48-55): 0x00000000feeddeca
%  high seqno (56-63): 0x0000000000000000
-spec encode_stream_request(partition_id(), request_id(), non_neg_integer(),
                            update_seq(), update_seq(),
                            {uuid(), update_seq()}) -> binary().
encode_stream_request(PartId, RequestId, Flags, StartSeq, EndSeq,
        {PartUuid, PartHighSeq}) ->
    Body = <<Flags:?UPR_SIZES_FLAGS,
             0:?UPR_SIZES_RESERVED,
             StartSeq:?UPR_SIZES_BY_SEQ,
             EndSeq:?UPR_SIZES_BY_SEQ,
             PartUuid:?UPR_SIZES_PARTITION_UUID/integer,
             PartHighSeq:?UPR_SIZES_BY_SEQ>>,

    BodyLength = byte_size(Body),
    ExtraLength = BodyLength,

    Header = <<?UPR_MAGIC_REQUEST,
               ?UPR_OPCODE_STREAM_REQUEST,
               0:?UPR_SIZES_KEY_LENGTH,
               ExtraLength,
               0,
               PartId:?UPR_SIZES_PARTITION,
               BodyLength:?UPR_SIZES_BODY,
               RequestId:?UPR_SIZES_OPAQUE,
               0:?UPR_SIZES_CAS>>,
    <<Header/binary, Body/binary>>.


%UPR_CLOSE_STREAM command
%Field        (offset) (value)
%Magic        (0)    : 0x80
%Opcode       (1)    : 0x52
%Key length   (2,3)  : 0x0000
%Extra length (4)    : 0x00
%Data type    (5)    : 0x00
%Vbucket      (6,7)  : 0x0005
%Total body   (8-11) : 0x00000000
%Opaque       (12-15): 0xdeadbeef
%CAS          (16-23): 0x0000000000000000
encode_stream_close(PartId, RequestId) ->
    Header = <<?UPR_MAGIC_REQUEST,
               ?UPR_OPCODE_STREAM_CLOSE,
               0:?UPR_SIZES_KEY_LENGTH,
               0,
               0,
               PartId:?UPR_SIZES_PARTITION,
               0:?UPR_SIZES_BODY,
               RequestId:?UPR_SIZES_OPAQUE,
               0:?UPR_SIZES_CAS>>,
    Header.

%UPR_GET_FAILOVER_LOG command
%Field        (offset) (value)
%Magic        (0)    : 0x80
%Opcode       (1)    : 0x54
%Key length   (2,3)  : 0x0000
%Extra length (4)    : 0x00
%Data type    (5)    : 0x00
%Vbucket      (6,7)  : 0x0000
%Total body   (8-11) : 0x00000000
%Opaque       (12-15): 0xdeadbeef
%CAS          (16-23): 0x0000000000000000
-spec encode_failover_log_request(partition_id(), request_id()) -> binary().
encode_failover_log_request(PartId, RequestId) ->
    Header = <<?UPR_MAGIC_REQUEST,
               ?UPR_OPCODE_FAILOVER_LOG_REQUEST,
               0:?UPR_SIZES_KEY_LENGTH,
               0,
               0,
               PartId:?UPR_SIZES_PARTITION,
               0:?UPR_SIZES_BODY,
               RequestId:?UPR_SIZES_OPAQUE,
               0:?UPR_SIZES_CAS>>,
    <<Header/binary>>.


%Field        (offset) (value)
%Magic        (0)    : 0x80
%Opcode       (1)    : 0x10
%Key length   (2,3)  : 0x000e
%Extra length (4)    : 0x00
%Data type    (5)    : 0x00
%VBucket      (6,7)  : 0x0001
%Total body   (8-11) : 0x0000000e
%Opaque       (12-15): 0x00000000
%CAS          (16-23): 0x0000000000000000
%Key                 : vbucket-seqno 1
-spec encode_stat_request(binary(), partition_id(), request_id()) -> binary().
encode_stat_request(Stat, PartId, RequestId) ->
    Body = <<Stat/binary, " ",
        (list_to_binary(integer_to_list(PartId)))/binary>>,

    KeyLength = BodyLength = byte_size(Body),
    ExtraLength = 0,

    Header = <<?UPR_MAGIC_REQUEST,
               ?UPR_OPCODE_STATS,
               KeyLength:?UPR_SIZES_KEY_LENGTH,
               ExtraLength,
               0,
               PartId:?UPR_SIZES_PARTITION,
               BodyLength:?UPR_SIZES_BODY,
               RequestId:?UPR_SIZES_OPAQUE,
               0:?UPR_SIZES_CAS>>,
    <<Header/binary, Body/binary>>.

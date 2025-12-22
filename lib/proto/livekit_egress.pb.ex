defmodule Livekit.EncodedFileType do
  
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :DEFAULT_FILETYPE, 0
  field :MP4, 1
  field :OGG, 2
  field :MP3, 3
end

defmodule Livekit.SegmentedFileProtocol do
  
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :DEFAULT_SEGMENTED_FILE_PROTOCOL, 0
  field :HLS_PROTOCOL, 1
end

defmodule Livekit.SegmentedFileSuffix do
  
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :INDEX, 0
  field :TIMESTAMP, 1
end

defmodule Livekit.ImageFileSuffix do
  
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :IMAGE_SUFFIX_INDEX, 0
  field :IMAGE_SUFFIX_TIMESTAMP, 1
  field :IMAGE_SUFFIX_NONE_OVERWRITE, 2
end

defmodule Livekit.StreamProtocol do
  
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :DEFAULT_PROTOCOL, 0
  field :RTMP, 1
  field :SRT, 2
end

defmodule Livekit.AudioMixing do
  
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :DEFAULT_MIXING, 0
  field :DUAL_CHANNEL_AGENT, 1
  field :DUAL_CHANNEL_ALTERNATE, 2
end

defmodule Livekit.EncodingOptionsPreset do
  
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :H264_720P_30, 0
  field :H264_720P_60, 1
  field :H264_1080P_30, 2
  field :H264_1080P_60, 3
  field :PORTRAIT_H264_720P_30, 4
  field :PORTRAIT_H264_720P_60, 5
  field :PORTRAIT_H264_1080P_30, 6
  field :PORTRAIT_H264_1080P_60, 7
end

defmodule Livekit.EgressStatus do
  
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :EGRESS_STARTING, 0
  field :EGRESS_ACTIVE, 1
  field :EGRESS_ENDING, 2
  field :EGRESS_COMPLETE, 3
  field :EGRESS_FAILED, 4
  field :EGRESS_ABORTED, 5
  field :EGRESS_LIMIT_REACHED, 6
end

defmodule Livekit.EgressSourceType do
  
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :EGRESS_SOURCE_TYPE_WEB, 0
  field :EGRESS_SOURCE_TYPE_SDK, 1
end

defmodule Livekit.StreamInfo.Status do
  
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :ACTIVE, 0
  field :FINISHED, 1
  field :FAILED, 2
end

defmodule Livekit.RoomCompositeEgressRequest do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :output, 0

  oneof :options, 1

  field :room_name, 1, type: :string, json_name: "roomName"
  field :layout, 2, type: :string
  field :audio_only, 3, type: :bool, json_name: "audioOnly"
  field :audio_mixing, 15, type: Livekit.AudioMixing, json_name: "audioMixing", enum: true
  field :video_only, 4, type: :bool, json_name: "videoOnly"
  field :custom_base_url, 5, type: :string, json_name: "customBaseUrl"
  field :file, 6, type: Livekit.EncodedFileOutput, oneof: 0, deprecated: true
  field :stream, 7, type: Livekit.StreamOutput, oneof: 0, deprecated: true
  field :segments, 10, type: Livekit.SegmentedFileOutput, oneof: 0, deprecated: true
  field :preset, 8, type: Livekit.EncodingOptionsPreset, enum: true, oneof: 1
  field :advanced, 9, type: Livekit.EncodingOptions, oneof: 1

  field :file_outputs, 11,
    repeated: true,
    type: Livekit.EncodedFileOutput,
    json_name: "fileOutputs"

  field :stream_outputs, 12,
    repeated: true,
    type: Livekit.StreamOutput,
    json_name: "streamOutputs"

  field :segment_outputs, 13,
    repeated: true,
    type: Livekit.SegmentedFileOutput,
    json_name: "segmentOutputs"

  field :image_outputs, 14, repeated: true, type: Livekit.ImageOutput, json_name: "imageOutputs"
  field :webhooks, 16, repeated: true, type: Livekit.WebhookConfig
end

defmodule Livekit.WebEgressRequest do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :output, 0

  oneof :options, 1

  field :url, 1, type: :string
  field :audio_only, 2, type: :bool, json_name: "audioOnly"
  field :video_only, 3, type: :bool, json_name: "videoOnly"
  field :await_start_signal, 12, type: :bool, json_name: "awaitStartSignal"
  field :file, 4, type: Livekit.EncodedFileOutput, oneof: 0, deprecated: true
  field :stream, 5, type: Livekit.StreamOutput, oneof: 0, deprecated: true
  field :segments, 6, type: Livekit.SegmentedFileOutput, oneof: 0, deprecated: true
  field :preset, 7, type: Livekit.EncodingOptionsPreset, enum: true, oneof: 1
  field :advanced, 8, type: Livekit.EncodingOptions, oneof: 1

  field :file_outputs, 9,
    repeated: true,
    type: Livekit.EncodedFileOutput,
    json_name: "fileOutputs"

  field :stream_outputs, 10,
    repeated: true,
    type: Livekit.StreamOutput,
    json_name: "streamOutputs"

  field :segment_outputs, 11,
    repeated: true,
    type: Livekit.SegmentedFileOutput,
    json_name: "segmentOutputs"

  field :image_outputs, 13, repeated: true, type: Livekit.ImageOutput, json_name: "imageOutputs"
  field :webhooks, 14, repeated: true, type: Livekit.WebhookConfig
end

defmodule Livekit.ParticipantEgressRequest do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :options, 0

  field :room_name, 1, type: :string, json_name: "roomName"
  field :identity, 2, type: :string
  field :screen_share, 3, type: :bool, json_name: "screenShare"
  field :preset, 4, type: Livekit.EncodingOptionsPreset, enum: true, oneof: 0
  field :advanced, 5, type: Livekit.EncodingOptions, oneof: 0

  field :file_outputs, 6,
    repeated: true,
    type: Livekit.EncodedFileOutput,
    json_name: "fileOutputs"

  field :stream_outputs, 7, repeated: true, type: Livekit.StreamOutput, json_name: "streamOutputs"

  field :segment_outputs, 8,
    repeated: true,
    type: Livekit.SegmentedFileOutput,
    json_name: "segmentOutputs"

  field :image_outputs, 9, repeated: true, type: Livekit.ImageOutput, json_name: "imageOutputs"
  field :webhooks, 10, repeated: true, type: Livekit.WebhookConfig
end

defmodule Livekit.TrackCompositeEgressRequest do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :output, 0

  oneof :options, 1

  field :room_name, 1, type: :string, json_name: "roomName"
  field :audio_track_id, 2, type: :string, json_name: "audioTrackId"
  field :video_track_id, 3, type: :string, json_name: "videoTrackId"
  field :file, 4, type: Livekit.EncodedFileOutput, oneof: 0, deprecated: true
  field :stream, 5, type: Livekit.StreamOutput, oneof: 0, deprecated: true
  field :segments, 8, type: Livekit.SegmentedFileOutput, oneof: 0, deprecated: true
  field :preset, 6, type: Livekit.EncodingOptionsPreset, enum: true, oneof: 1
  field :advanced, 7, type: Livekit.EncodingOptions, oneof: 1

  field :file_outputs, 11,
    repeated: true,
    type: Livekit.EncodedFileOutput,
    json_name: "fileOutputs"

  field :stream_outputs, 12,
    repeated: true,
    type: Livekit.StreamOutput,
    json_name: "streamOutputs"

  field :segment_outputs, 13,
    repeated: true,
    type: Livekit.SegmentedFileOutput,
    json_name: "segmentOutputs"

  field :image_outputs, 14, repeated: true, type: Livekit.ImageOutput, json_name: "imageOutputs"
  field :webhooks, 15, repeated: true, type: Livekit.WebhookConfig
end

defmodule Livekit.TrackEgressRequest do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :output, 0

  field :room_name, 1, type: :string, json_name: "roomName"
  field :track_id, 2, type: :string, json_name: "trackId"
  field :file, 3, type: Livekit.DirectFileOutput, oneof: 0
  field :websocket_url, 4, type: :string, json_name: "websocketUrl", oneof: 0
  field :webhooks, 5, repeated: true, type: Livekit.WebhookConfig
end

defmodule Livekit.EncodedFileOutput do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :output, 0

  field :file_type, 1, type: Livekit.EncodedFileType, json_name: "fileType", enum: true
  field :filepath, 2, type: :string
  field :disable_manifest, 6, type: :bool, json_name: "disableManifest"
  field :s3, 3, type: Livekit.S3Upload, oneof: 0
  field :gcp, 4, type: Livekit.GCPUpload, oneof: 0
  field :azure, 5, type: Livekit.AzureBlobUpload, oneof: 0
  field :aliOSS, 7, type: Livekit.AliOSSUpload, oneof: 0
end

defmodule Livekit.SegmentedFileOutput do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :output, 0

  field :protocol, 1, type: Livekit.SegmentedFileProtocol, enum: true
  field :filename_prefix, 2, type: :string, json_name: "filenamePrefix"
  field :playlist_name, 3, type: :string, json_name: "playlistName"
  field :live_playlist_name, 11, type: :string, json_name: "livePlaylistName"
  field :segment_duration, 4, type: :uint32, json_name: "segmentDuration"

  field :filename_suffix, 10,
    type: Livekit.SegmentedFileSuffix,
    json_name: "filenameSuffix",
    enum: true

  field :disable_manifest, 8, type: :bool, json_name: "disableManifest"
  field :s3, 5, type: Livekit.S3Upload, oneof: 0
  field :gcp, 6, type: Livekit.GCPUpload, oneof: 0
  field :azure, 7, type: Livekit.AzureBlobUpload, oneof: 0
  field :aliOSS, 9, type: Livekit.AliOSSUpload, oneof: 0
end

defmodule Livekit.DirectFileOutput do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :output, 0

  field :filepath, 1, type: :string
  field :disable_manifest, 5, type: :bool, json_name: "disableManifest"
  field :s3, 2, type: Livekit.S3Upload, oneof: 0
  field :gcp, 3, type: Livekit.GCPUpload, oneof: 0
  field :azure, 4, type: Livekit.AzureBlobUpload, oneof: 0
  field :aliOSS, 6, type: Livekit.AliOSSUpload, oneof: 0
end

defmodule Livekit.ImageOutput do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :output, 0

  field :capture_interval, 1, type: :uint32, json_name: "captureInterval"
  field :width, 2, type: :int32
  field :height, 3, type: :int32
  field :filename_prefix, 4, type: :string, json_name: "filenamePrefix"

  field :filename_suffix, 5,
    type: Livekit.ImageFileSuffix,
    json_name: "filenameSuffix",
    enum: true

  field :image_codec, 6, type: Livekit.ImageCodec, json_name: "imageCodec", enum: true
  field :disable_manifest, 7, type: :bool, json_name: "disableManifest"
  field :s3, 8, type: Livekit.S3Upload, oneof: 0
  field :gcp, 9, type: Livekit.GCPUpload, oneof: 0
  field :azure, 10, type: Livekit.AzureBlobUpload, oneof: 0
  field :aliOSS, 11, type: Livekit.AliOSSUpload, oneof: 0
end

defmodule Livekit.S3Upload.MetadataEntry do
  
  use Protobuf, map: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule Livekit.S3Upload do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :access_key, 1, type: :string, json_name: "accessKey", deprecated: false
  field :secret, 2, type: :string, deprecated: false
  field :session_token, 11, type: :string, json_name: "sessionToken", deprecated: false
  field :assume_role_arn, 12, type: :string, json_name: "assumeRoleArn", deprecated: false
  field :assume_role_external_id, 13, type: :string, json_name: "assumeRoleExternalId"
  field :region, 3, type: :string
  field :endpoint, 4, type: :string
  field :bucket, 5, type: :string
  field :force_path_style, 6, type: :bool, json_name: "forcePathStyle"
  field :metadata, 7, repeated: true, type: Livekit.S3Upload.MetadataEntry, map: true
  field :tagging, 8, type: :string
  field :content_disposition, 9, type: :string, json_name: "contentDisposition"
  field :proxy, 10, type: Livekit.ProxyConfig
end

defmodule Livekit.GCPUpload do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :credentials, 1, type: :string, deprecated: false
  field :bucket, 2, type: :string
  field :proxy, 3, type: Livekit.ProxyConfig
end

defmodule Livekit.AzureBlobUpload do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :account_name, 1, type: :string, json_name: "accountName", deprecated: false
  field :account_key, 2, type: :string, json_name: "accountKey", deprecated: false
  field :container_name, 3, type: :string, json_name: "containerName"
end

defmodule Livekit.AliOSSUpload do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :access_key, 1, type: :string, json_name: "accessKey", deprecated: false
  field :secret, 2, type: :string, deprecated: false
  field :region, 3, type: :string
  field :endpoint, 4, type: :string
  field :bucket, 5, type: :string
end

defmodule Livekit.ProxyConfig do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :url, 1, type: :string
  field :username, 2, type: :string
  field :password, 3, type: :string
end

defmodule Livekit.StreamOutput do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :protocol, 1, type: Livekit.StreamProtocol, enum: true
  field :urls, 2, repeated: true, type: :string
end

defmodule Livekit.EncodingOptions do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :width, 1, type: :int32
  field :height, 2, type: :int32
  field :depth, 3, type: :int32
  field :framerate, 4, type: :int32
  field :audio_codec, 5, type: Livekit.AudioCodec, json_name: "audioCodec", enum: true
  field :audio_bitrate, 6, type: :int32, json_name: "audioBitrate"
  field :audio_quality, 11, type: :int32, json_name: "audioQuality"
  field :audio_frequency, 7, type: :int32, json_name: "audioFrequency"
  field :video_codec, 8, type: Livekit.VideoCodec, json_name: "videoCodec", enum: true
  field :video_bitrate, 9, type: :int32, json_name: "videoBitrate"
  field :video_quality, 12, type: :int32, json_name: "videoQuality"
  field :key_frame_interval, 10, type: :double, json_name: "keyFrameInterval"
end

defmodule Livekit.UpdateLayoutRequest do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :egress_id, 1, type: :string, json_name: "egressId"
  field :layout, 2, type: :string
end

defmodule Livekit.UpdateStreamRequest do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :egress_id, 1, type: :string, json_name: "egressId"
  field :add_output_urls, 2, repeated: true, type: :string, json_name: "addOutputUrls"
  field :remove_output_urls, 3, repeated: true, type: :string, json_name: "removeOutputUrls"
end

defmodule Livekit.ListEgressRequest do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :room_name, 1, type: :string, json_name: "roomName"
  field :egress_id, 2, type: :string, json_name: "egressId"
  field :active, 3, type: :bool
end

defmodule Livekit.ListEgressResponse do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :items, 1, repeated: true, type: Livekit.EgressInfo
end

defmodule Livekit.StopEgressRequest do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :egress_id, 1, type: :string, json_name: "egressId"
end

defmodule Livekit.EgressInfo do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :request, 0

  oneof :result, 1

  field :egress_id, 1, type: :string, json_name: "egressId"
  field :room_id, 2, type: :string, json_name: "roomId"
  field :room_name, 13, type: :string, json_name: "roomName"
  field :source_type, 26, type: Livekit.EgressSourceType, json_name: "sourceType", enum: true
  field :status, 3, type: Livekit.EgressStatus, enum: true
  field :started_at, 10, type: :int64, json_name: "startedAt"
  field :ended_at, 11, type: :int64, json_name: "endedAt"
  field :updated_at, 18, type: :int64, json_name: "updatedAt"
  field :details, 21, type: :string
  field :error, 9, type: :string
  field :error_code, 22, type: :int32, json_name: "errorCode"

  field :room_composite, 4,
    type: Livekit.RoomCompositeEgressRequest,
    json_name: "roomComposite",
    oneof: 0

  field :web, 14, type: Livekit.WebEgressRequest, oneof: 0
  field :participant, 19, type: Livekit.ParticipantEgressRequest, oneof: 0

  field :track_composite, 5,
    type: Livekit.TrackCompositeEgressRequest,
    json_name: "trackComposite",
    oneof: 0

  field :track, 6, type: Livekit.TrackEgressRequest, oneof: 0
  field :stream, 7, type: Livekit.StreamInfoList, oneof: 1, deprecated: true
  field :file, 8, type: Livekit.FileInfo, oneof: 1, deprecated: true
  field :segments, 12, type: Livekit.SegmentsInfo, oneof: 1, deprecated: true
  field :stream_results, 15, repeated: true, type: Livekit.StreamInfo, json_name: "streamResults"
  field :file_results, 16, repeated: true, type: Livekit.FileInfo, json_name: "fileResults"

  field :segment_results, 17,
    repeated: true,
    type: Livekit.SegmentsInfo,
    json_name: "segmentResults"

  field :image_results, 20, repeated: true, type: Livekit.ImagesInfo, json_name: "imageResults"
  field :manifest_location, 23, type: :string, json_name: "manifestLocation"
  field :backup_storage_used, 25, type: :bool, json_name: "backupStorageUsed"
end

defmodule Livekit.StreamInfoList do
  
  use Protobuf, deprecated: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :info, 1, repeated: true, type: Livekit.StreamInfo
end

defmodule Livekit.StreamInfo do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :url, 1, type: :string
  field :started_at, 2, type: :int64, json_name: "startedAt"
  field :ended_at, 3, type: :int64, json_name: "endedAt"
  field :duration, 4, type: :int64
  field :status, 5, type: Livekit.StreamInfo.Status, enum: true
  field :error, 6, type: :string
  field :last_retry_at, 7, type: :int64, json_name: "lastRetryAt"
  field :retries, 8, type: :uint32
end

defmodule Livekit.FileInfo do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :filename, 1, type: :string
  field :started_at, 2, type: :int64, json_name: "startedAt"
  field :ended_at, 3, type: :int64, json_name: "endedAt"
  field :duration, 6, type: :int64
  field :size, 4, type: :int64
  field :location, 5, type: :string
end

defmodule Livekit.SegmentsInfo do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :playlist_name, 1, type: :string, json_name: "playlistName"
  field :live_playlist_name, 8, type: :string, json_name: "livePlaylistName"
  field :duration, 2, type: :int64
  field :size, 3, type: :int64
  field :playlist_location, 4, type: :string, json_name: "playlistLocation"
  field :live_playlist_location, 9, type: :string, json_name: "livePlaylistLocation"
  field :segment_count, 5, type: :int64, json_name: "segmentCount"
  field :started_at, 6, type: :int64, json_name: "startedAt"
  field :ended_at, 7, type: :int64, json_name: "endedAt"
end

defmodule Livekit.ImagesInfo do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :filename_prefix, 4, type: :string, json_name: "filenamePrefix"
  field :image_count, 1, type: :int64, json_name: "imageCount"
  field :started_at, 2, type: :int64, json_name: "startedAt"
  field :ended_at, 3, type: :int64, json_name: "endedAt"
end

defmodule Livekit.AutoParticipantEgress do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :options, 0

  field :preset, 1, type: Livekit.EncodingOptionsPreset, enum: true, oneof: 0
  field :advanced, 2, type: Livekit.EncodingOptions, oneof: 0

  field :file_outputs, 3,
    repeated: true,
    type: Livekit.EncodedFileOutput,
    json_name: "fileOutputs"

  field :segment_outputs, 4,
    repeated: true,
    type: Livekit.SegmentedFileOutput,
    json_name: "segmentOutputs"
end

defmodule Livekit.AutoTrackEgress do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :output, 0

  field :filepath, 1, type: :string
  field :disable_manifest, 5, type: :bool, json_name: "disableManifest"
  field :s3, 2, type: Livekit.S3Upload, oneof: 0
  field :gcp, 3, type: Livekit.GCPUpload, oneof: 0
  field :azure, 4, type: Livekit.AzureBlobUpload, oneof: 0
  field :aliOSS, 6, type: Livekit.AliOSSUpload, oneof: 0
end

class VideoTile {
  final int tileId;
  int videoStreamContentWidth;
  int videoStreamContentHeight;
  bool isLocalTile;
  bool isContentShare;

  VideoTile(this.tileId, this.videoStreamContentWidth,
      this.videoStreamContentHeight, this.isLocalTile, this.isContentShare);

  factory VideoTile.fromJson(json) {
    return VideoTile(
        json["tileId"],
        json["videoStreamContentWidth"],
        json["videoStreamContentHeight"],
        json["isLocalTile"],
        json["isContent"]);
  }
}

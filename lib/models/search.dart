import 'album.dart';
import 'song.dart';
import 'artist.dart';

class MusicSearch {
  final String? term;
  final List<Album>? albums;
  final List<Song>? songs;
  final List<Artist>? artists;

  MusicSearch({this.albums, this.songs, this.artists, this.term});

  int get totalCount {
    if (albums != null && songs != null && artists != null) {
      return albums!.length + songs!.length + artists!.length;
    } else {
      return 0;
    }
  }

  bool get isEmpty => totalCount == 0;
}

library apple_music_api;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import './models/index.dart';

class AppleMusic {
  // Initialize with the JWT KEY //
  AppleMusic({required this.jwtKey});

  static const STOREFRONT = 'us';
  static const BASE_URL = 'https://api.music.apple.com/v1/catalog';
  static const GENRE_URL = "$BASE_URL/$STOREFRONT/genres";
  static const _SONG_URL = "$BASE_URL/$STOREFRONT/songs";
  static const _ALBUM_URL = "$BASE_URL/$STOREFRONT/albums";
  static const _CHART_URL = "$BASE_URL/$STOREFRONT/charts";
  static const _ARTIST_URL = "$BASE_URL/$STOREFRONT/artists";
  static const _SEARCH_URL = "$BASE_URL/$STOREFRONT/search";
  late final jwtKey;

  Future<dynamic> _fetchJSON(String url) async {
    try {
      Uri uri = Uri.parse(url);
      final response =
          await http.get(uri, headers: {'authorization': "Bearer $jwtKey"});
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch data');
      }
    } on Exception catch (e) {
      print('[AppleMusicAPI] _fetchJSON error: $e');
      throw e;
    }
  }

  Future<Song> fetchSongById(String id) async {
    try {
      final json = await _fetchJSON("$_SONG_URL/$id");
      return Song.fromJson(json['data'][0]);
    } on Exception catch (e) {
      print('[AppleMusicAPI] fetchSongById error: $e');
      throw e;
    }
  }

  Future<List<Genre>> fetchGenres() async {
    try {
      final json = await _fetchJSON(GENRE_URL);
      final data = json['data'] as List;
      final genres = data.map((d) => Genre.fromJson(d));
      return genres.toList();
    } on Exception catch (e) {
      print('[AppleMusicAPI] fetchGenres error: $e');
      throw e;
    }
  }

  Future<Album> fetchAlbumById(String id) async {
    try {
      final json = await _fetchJSON("$_ALBUM_URL/$id");
      return Album.fromJson(json['data'][0]);
    } on Exception catch (e) {
      print('[AppleMusicAPI] fetchAlbumById error: $e');
      throw e;
    }
  }

  Future<Artist> fetchArtistById(String id) async {
    try {
      final json = await _fetchJSON("$_ARTIST_URL/$id?include=albums,songs");
      return Artist.fromJson(json['data'][0]);
    } on Exception catch (e) {
      // TODO
      print('[AppleMusicAPI] fetchArtistById error: $e');
      throw e;
    }
  }

  Future<Chart> fetchTopChart() async {
    try {
      final url = "$_CHART_URL?types=songs,albums";
      final json = await _fetchJSON(url);
      final songChartJSON = json['results']['songs'][0];
      final songChart = SongChart.fromJson(songChartJSON);

      final albumChartJSON = json['results']['albums'][0];
      final albumChart = AlbumChart.fromJson(albumChartJSON);

      final chart = Chart(albumChart: albumChart, songChart: songChart);
      return chart;
    } on Exception catch (e) {
      print('[AppleMusicAPI] fetchTopChart error: $e');
      throw e;
    }
  }

  Future<MusicSearch> search(String query,
      {List<QueryType> queryTypes = QueryType.values}) async {
    final url =
        "$_SEARCH_URL?types=${_queryType(queryTypes)}&limit=15&term=$query";
    final encoded = Uri.encodeFull(url);
    final json = await _fetchJSON(encoded);

    final List<Album> albums = [];
    final List<Song> songs = [];
    final List<Artist> artists = [];

    final artistJSON = json['results']['artists'];
    if (artistJSON != null) {
      artists
          .addAll((artistJSON['data'] as List).map((a) => Artist.fromJson(a)));
    }

    final albumsJSON = json['results']['albums'];
    if (albumsJSON != null) {
      albums.addAll((albumsJSON['data'] as List).map((a) => Album.fromJson(a)));
    }

    final songJSON = json['results']['songs'];
    if (songJSON != null) {
      songs.addAll((songJSON['data'] as List).map((a) => Song.fromJson(a)));
    }

    return MusicSearch(
        albums: albums, songs: songs, artists: artists, term: query);
  }

  String _queryType(List<QueryType> queryTypes) {
    String queryType = '';
    queryTypes.forEach((type) {
      queryType += type.title + ',';
    });
    return queryType.substring(
        0, queryType.length > 0 ? queryType.length - 1 : 0);
  }
}

enum QueryType {
  song,
  artist,
  album,
}

extension QueryTypeExtension on QueryType {
  String get title {
    switch (this) {
      case QueryType.album:
        return 'albums';
      case QueryType.song:
        return 'songs';
      case QueryType.artist:
        return 'artist';
      default:
        return '';
    }
  }
}

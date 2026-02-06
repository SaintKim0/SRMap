/// KMDb API에서 가져온 작품 정보 (제목, 감독, 연도, 줄거리 등)
class KmdbWorkInfo {
  final String title;
  final String? directorNm;
  final String? prodYear;
  final String? plot;
  final String? nation;
  final String? genre;
  final String? kmdbUrl;

  const KmdbWorkInfo({
    required this.title,
    this.directorNm,
    this.prodYear,
    this.plot,
    this.nation,
    this.genre,
    this.kmdbUrl,
  });

  bool get hasAnyInfo =>
      (directorNm != null && directorNm!.isNotEmpty) ||
      (prodYear != null && prodYear!.isNotEmpty) ||
      (plot != null && plot!.isNotEmpty);
}
